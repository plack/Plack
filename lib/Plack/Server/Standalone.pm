package Plack::Server::Standalone;
use strict;
use warnings;

use Plack::HTTPParser qw( parse_http_request );
use IO::Socket::INET;
use HTTP::Date;
use HTTP::Status;
use List::Util qw(max sum);
use Plack::Util;
use Plack::Middleware::ContentLength;
use POSIX qw(EINTR);
use Socket qw(IPPROTO_TCP TCP_NODELAY);
use Time::HiRes qw(alarm time);

use constant MAX_REQUEST_SIZE => 131072;
use constant MSWin32          => $^O eq 'MSWin32';

our $HasSendFile = !$ENV{PLACK_NO_SENDFILE} && do {
    local $@;
    eval { require Sys::Sendfile; 1 };
};

sub new {
    my($class, %args) = @_;
    my $self = bless {
        host               => $args{host} || 0,
        port               => $args{port} || 8080,
        timeout            => $args{timeout} || 300,
        max_keepalive_reqs => $args{max_keepalive_reqs} || 100,
        keepalive_timeout  => $args{keepalive_timeout} || 2,
    }, $class;

    $self;
}

sub run {
    my($self, $app) = @_;
    $self->setup_listener();
    $self->accept_loop($app);
}

sub setup_listener {
    my $self = shift;
    $self->{listen_sock} ||= IO::Socket::INET->new(
        Listen    => SOMAXCONN,
        LocalPort => $self->{port},
        LocalAddr => $self->{host},
        Proto     => 'tcp',
        ReuseAddr => 1,
    ) or die "failed to listen to port $self->{port}:$!";
    warn "Accepting connections at http://$self->{host}:$self->{port}/\n";
}

sub accept_loop {
    # TODO handle $max_reqs_per_child
    my($self, $app, $max_reqs_per_child) = @_;
    my $proc_req_count = 0;

    $app = Plack::Middleware::ContentLength->wrap($app);

    while (! defined $max_reqs_per_child || $proc_req_count < $max_reqs_per_child) {
        local $SIG{PIPE} = 'IGNORE';
        if (my $conn = $self->{listen_sock}->accept) {
            $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1)
                or die "setsockopt(TCP_NODELAY) failed:$!";
            my $req_count = 0;
            while (1) {
                ++$req_count;
                ++$proc_req_count;
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
                my $may_keepalive = $req_count < $self->{max_keepalive_reqs};
                if ($may_keepalive && $max_reqs_per_child && $proc_req_count >= $max_reqs_per_child) {
                    $may_keepalive = undef;
                }
                $self->handle_connection($env, $conn, $app, $may_keepalive, $req_count != 0)
                    or last;
                # TODO add special cases for clients with broken keep-alive support, as well as disabling keep-alive for HTTP/1.0 proxies
            }
        }
    }
}

sub handle_connection {
    my($self, $env, $conn, $app, $use_keepalive, $is_keepalive) = @_;

    my $buf = '';
    my $res = [ 400, [ 'Content-Type' => 'text/plain' ], [ 'Bad Request' ] ];

    while (1) {
        my $rlen = $self->read_timeout(
            $conn, \$buf, MAX_REQUEST_SIZE - length($buf), length($buf),
            $is_keepalive || length($buf) != 0
                ? $self->{keepalive_timeout} : $self->{timeout},
        ) or return;
        my $reqlen = parse_http_request($buf, $env);
        if ($reqlen >= 0) {
            # handle request
            if ($use_keepalive) {
                if (my $c = $env->{HTTP_CONNECTION}) {
                    $use_keepalive = undef
                        unless $c =~ /^\s*keep-alive\s*/i;
                } else {
                    $use_keepalive = undef;
                }
            }
            $buf = substr $buf, $reqlen;
            if ($env->{CONTENT_LENGTH}) {
                # TODO can $conn seek to the begining of body and then set to 'psgi.input'?
                while (length $buf < $env->{CONTENT_LENGTH}) {
                    $self->read_timeout($conn, \$buf, $env->{CONTENT_LENGTH} - length($buf), length($buf), $self->{timeout})
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

    my $conn_value;
    my @lines = (
        "Date: @{[HTTP::Date::time2str()]}\015\012",
        "Server: Plack-Server-Standalone/$Plack::VERSION\015\012",
    );

    Plack::Util::header_iter($res->[1], sub {
        my ($k, $v) = @_;
        if (lc $k eq 'connection') {
            $use_keepalive = undef
                if $use_keepalive && lc $v ne 'keep-alive';
        } else {
            push @lines, "$k: $v\015\012";
        }
    });
    if ($use_keepalive) {
        $use_keepalive = undef
            unless Plack::Util::header_exists($res->[1], 'Content-Length');
    }
    push @lines, "Connection: keep-alive\015\012"
        if $use_keepalive;
    unshift @lines, "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\015\012";
    push @lines, "\015\012";

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
    $use_keepalive;
}

# returns 1 if socket is ready, undef on timeout
sub do_timeout {
    my ($self, $cb, $timeout) = @_;
    local $SIG{ALRM} = sub {};
    my $wait_until = time + $timeout;
    alarm($timeout);
    my $ret;
    while (1) {
        if ($ret = $cb->()) {
            last;
        } elsif (! (! defined($ret) && $! == EINTR)) {
            undef $ret;
            last;
        }
        # got EINTR
        my $left = $wait_until - time;
        last if $left <= 0;
        alarm($left + 0.1);
    }
    alarm(0);
    $ret;
}

# returns (positive) number of bytes read, or undef if the socket is to be closed
sub read_timeout {
    my ($self, $sock, $buf, $len, $off, $timeout) = @_;
    $self->do_timeout(sub { $sock->sysread($$buf, $len, $off) }, $timeout);
}

# returns (positive) number of bytes written, or undef if the socket is to be closed
sub write_timeout {
    my ($self, $sock, $buf, $len, $off, $timeout) = @_;
    $self->do_timeout(sub { $sock->syswrite($buf, $len, $off) }, $timeout);
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
        my $r = $self->do_timeout(
            sub { Sys::Sendfile::sendfile($sock, $fd, $len - $off, $off) },
            $timeout,
        );
        return
            unless defined $r;
        $off += $r;
    }
    return $off;
}

1;

__END__

=head1 NAME

Plack::Server::Standalone - single process standalone HTTP server

=head1 SYNOPSIS

  % plackup -s Standalone \
      --host 127.0.0.1 --port 9091 --timeout 120 \
      --max-keepalive-reqs 20 --keepalive-timeout 5

=head1 DESCRIPTION

Plack::Server::Standalone is a default Plack server implementation
that runs as a standalone, single-process and reasonably fast HTTP
server. HTTP/1.0 and Keep-Alive requests are supported.

See L<Plack::Server::Standalone::Prefork> if you want a multi-process
prefork server.

Some features in HTTP/1.1, notably chunked requests, responses and
pipeline requests are B<NOT> supported yet.

=head1 CONFIGURATIONS

=over 4

=item host

Host the server binds to. Defaults to all interfaces.

=item port

Port number the server listens on. Defaults to 8080.

=item timeout

Number of seconds a request times out. Defaults to 300.

=item max-keepalive-reqs

Max requests per a keep-alive request. Defaults to 100.

=item keepalive-timeout

Number of seconds a keep-alive request times out. Defaults to 2.

=back

=head1 AUTHOR

Kazuho Oku

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Server::Standalone::Prefork>

=cut
