package Plack::Server::Standalone;
use strict;
use warnings;

use Plack;
use Plack::HTTPParser qw( parse_http_request );
use Fcntl qw(F_SETFL FNDELAY);
use IO::Socket::INET;
use HTTP::Date;
use HTTP::Status;
use List::Util qw(max sum);
use Plack::Util;
use POSIX qw(EAGAIN);
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use Time::HiRes qw(time);

use constant MAX_REQUEST_SIZE   => 131072;

our $HasSendFile = do {
    local $@;
    eval { require Sys::Sendfile; 1 };
};

sub new {
    my($class, %args) = @_;
    bless {
        host               => $args{host} || 0,
        port               => $args{port} || 8080,
        timeout            => $args{timeout} || 300,
        max_keepalive_reqs => $args{max_keepalive_reqs} || 100,
        keepalive_timeout  => $args{keepalive_timeout} || 5,
    }, $class;
}

sub run {
    my($self, $app) = @_;

    my $listen_sock = IO::Socket::INET->new(
        Listen    => SOMAXCONN,
        LocalPort => $self->{port},
        LocalAddr => $self->{host},
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or die "failed to listen to port $self->{port}:$!";

    warn "Accepting connections at http://$self->{host}:$self->{port}/\n";
    while (1) {
        local $SIG{PIPE} = 'IGNORE';
        if (my $conn = $listen_sock->accept) {
            $conn->fcntl(F_SETFL, FNDELAY)
                or die "fcntl(FNDELAY) failed:$!";
            $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                or die "setsockopt(TCP_NODELAY) failed:$!";
            # we do not compare $req_count with $self->{max_keepalive_reqs} here, since it is an advisory variable and can be overridden by applications
            for (my $req_count = 1; ; ++$req_count) {
                my $env = {
                    SERVER_PORT => $self->{port},
                    SERVER_NAME => $self->{host},
                    SCRIPT_NAME => '',
                    REMOTE_ADDR => $conn->peerhost,
                    'psgi.version' => [ 1, 0 ],
                    'psgi.errors'  => *STDERR,
                    'psgi.url_scheme' => 'http',
                    'psgi.run_once'     => Plack::Util::FALSE,
                    'psgi.multithread'  => Plack::Util::FALSE,
                    'psgi.multiprocess' => Plack::Util::FALSE,
                };

                # no need to take care of pipelining since this module is a HTTP/1.0 server
                $self->handle_connection($env, $conn, $app, $req_count)
                    or last;
                # TODO add special cases for clients with broken keep-alive support, as well as disabling keep-alive for HTTP/1.0 proxies
            }
        }
    }
}

sub handle_connection {
    my($self, $env, $conn, $app, $req_count) = @_;

    my $buf = '';
    my $res = [ 400, [ 'Content-Type' => 'text/plain' ], [ 'Bad Request' ] ];

    while (1) {
        my $rlen = $self->read_timeout($conn, \$buf, MAX_REQUEST_SIZE - length($buf), length($buf), $req_count == 1 || length($buf) != 0 ? $self->{timeout} : $self->{keepalive_timeout})
            or return;
        my $reqlen = parse_http_request($buf, $env);
        if ($reqlen >= 0) {
            # handle request
            $buf = substr $buf, $reqlen;
            if ($env->{CONTENT_LENGTH}) {
                # TODO can $conn seek to the begining of body and then set to 'psgi.input'?
                while (length $buf < $env->{CONTENT_LENGTH}) {
                    $self->read_timeout($conn, \$buf, $env->{CONTENT_LENGTH} - length($buf), length($buf))
                        or return;
                }
            }

            open my $input, "<", \$buf;
            $env->{'psgi.input'} = $input;
            $res = Plack::Util::run_app $app, $env;
            last;
        }
        if ($reqlen == -2) {
            # request is incomplete, do nothing
        } elsif ($reqlen == -1) {
            # error, close conn
            last;
        }
    }

    my ($has_cl, $conn_value);
    my @lines = (
        "Date: @{[HTTP::Date::time2str()]}\015\012",
        "Server: Plack-Server-Standalone/$Plack::VERSION\015\012",
    );
    while (my ($k, $v) = splice(@{$res->[1]}, 0, 2)) {
        push @lines, "$k: $v\r\n";
        if ($k =~ /^(?:(content-length)|(connection))$/i) {
            if ($1) {
                $has_cl = 1;
            } else {
                $conn_value = $v;
            }
        }
    }
    if (! $has_cl && $res->[0] != 304 && ref $res->[2] eq 'ARRAY') {
        unshift @lines, "Content-Length: @{[sum map { length $_ } @{$res->[2]}]}\r\n";
        $has_cl = 1;
    }
    if ($req_count < $self->{max_keepalive_reqs} && $has_cl && ! defined($conn_value) && ($env->{HTTP_CONNECTION} || '') =~ /keep-alive/i) {
        unshift @lines, "Connection: keep-alive\r\n";
        $conn_value = "keep-alive";
    }
    unshift @lines, "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\r\n";
    push @lines, "\r\n";

    $self->write_all($conn, join('', @lines), $self->{timeout})
        or return;

    if ($HasSendFile && Plack::Util::is_real_fh($res->[2])) {
        $self->sendfile_all($conn, $res->[2], $self->{timeout});
    } else {
        my $err;
        my $done;
        {
            local $@;
            eval {
                Plack::Util::foreach(
                    $res->[2],
                    sub {
                        $self->write_all($conn, $_[0], $self->{timeout})
                            or die "failed to send all data\n";
                    },
                );
                $done = 1;
            };
            $err = $@;
        };
        unless ($done) {
            if ($err =~ /^failed to send all data\n/) {
                return;
            } else {
                die $err;
            }
        }
    }
    defined($conn_value) && $conn_value =~  /keep-alive/i;
}

# returns 1 if socket is ready, undef on timeout
sub wait_socket {
    my ($self, $sock, $is_write, $wait_until) = @_;
    do {
        my $vec = '';
        vec($vec, $sock->fileno, 1) = 1;
        if (select($is_write ? undef : $vec, $is_write ? $vec : undef, undef,
                   max($wait_until - time, 0)) > 0) {
            return 1;
        }
    } while (time < $wait_until);
    return;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub read_timeout {
    my ($self, $sock, $buf, $len, $off, $timeout) = @_;
    my $wait_until = time + $timeout;
    while ($self->wait_socket($sock, undef, $wait_until)) {
        if (my $ret = $sock->sysread($$buf, $len, $off)) {
            return $ret;
        } elsif (! (! defined($ret) && $! == EAGAIN)) {
            last;
        }
    }
    return;
}

# returns (positive) number of bytes written, or undef if the socket is to be closed
sub write_timeout {
    my ($self, $sock, $buf, $len, $off, $timeout) = @_;
    my $wait_until = time + $timeout;
    while ($self->wait_socket($sock, 1, $wait_until)) {
        if (my $ret = $sock->syswrite($buf, $len, $off)) {
            return $ret;
        } elsif (! (! defined($ret) && $! == EAGAIN)) {
            last;
        }
    }
    return;
}

# writes all data in buf and returns number of bytes written or undef if failed
sub write_all {
    my ($self, $sock, $buf, $timeout) = @_;
    my $off = 0;
    while (my $len = length($buf) - $off) {
        my $ret = $self->write_timeout($sock, $buf, $len, $off, $timeout)
            or return;
        $off += $ret;
    }
    return length $buf;
}

sub sendfile_all {
    # TODO fallback to write_all
    my ($self, $sock, $fd, $timeout) = @_;
    my $off = 0;
    my $len = -s $fd;
    die "TODO" unless defined $len;
    while ($off < $len) {
        return
            unless $self->wait_socket($sock, 1, time + $timeout);
        my $r = Sys::Sendfile::sendfile($sock, $fd, $len - $off, $off);
        return
            unless defined $r;
        $off += $r;
    }
    return $off;
}

1;
