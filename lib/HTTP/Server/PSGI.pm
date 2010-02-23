package HTTP::Server::PSGI;
use strict;
use warnings;

use Plack;
use Plack::HTTPParser qw( parse_http_request );
use IO::Socket::INET;
use HTTP::Date;
use HTTP::Status;
use List::Util qw(max sum);
use Plack::Util;
use Plack::TempBuffer;
use Plack::Middleware::ContentLength;
use POSIX qw(EINTR);
use Socket qw(IPPROTO_TCP TCP_NODELAY);

use Try::Tiny;
use Time::HiRes qw(time);

my $alarm_interval;
BEGIN {
    if ($^O eq 'MSWin32') {
        $alarm_interval = 1;
    } else {
        Time::HiRes->import('alarm');
        $alarm_interval = 0.1;
    }
}

use constant MAX_REQUEST_SIZE => 131072;
use constant MSWin32          => $^O eq 'MSWin32';

sub new {
    my($class, %args) = @_;

    my $self = bless {
        host               => $args{host} || 0,
        port               => $args{port} || 8080,
        timeout            => $args{timeout} || 300,
        keepalive_timeout  => $args{keepalive_timeout} || 2,
        max_keepalive_reqs => $args{max_keepalive_reqs},
        server_software    => $args{server_software} || $class,
        server_ready       => $args{server_ready} || sub {},
        max_workers        => $args{max_workers} || 1,
        max_reqs_per_child => $args{max_reqs_per_child} || 100,
    }, $class;

    if ($self->{max_workers} > 1) {
        try {
            require Parallel::Prefork;
            $self->{prefork} = 1;
            $self->{max_keepalive_reqs} ||= 100;
            $self->{server_software} .= " (prefork)";
        } catch {
            die "You need to install Parallel::Prefork to run multi workers (max_workers=$self->{max_workers}): $_";
        };
    }

    unless ($self->{prefork}) {
        $self->{max_keepalive_reqs} ||= 1;
    }

    $self;
}

sub run {
    my($self, $app) = @_;
    $self->setup_listener();

    if ($self->{prefork}) {
        $self->run_prefork($app);
    } else {
        $self->accept_loop($app);
    }
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

    $self->{server_ready}->($self);
}

sub run_prefork {
    my($self, $app) = @_;

    my $pm = Parallel::Prefork->new({
        max_workers => $self->{max_workers},
        trap_signals => {
            TERM => 'TERM',
            HUP  => 'TERM',
        },
    });
    while ($pm->signal_received ne 'TERM') {
        $pm->start and next;
        $self->accept_loop($app, $self->{max_reqs_per_child});
        $pm->finish;
    }
    $pm->wait_all_children;
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
                    'psgi.version' => [ 1, 1 ],
                    'psgi.errors'  => *STDERR,
                    'psgi.url_scheme' => 'http',
                    'psgi.run_once'     => Plack::Util::FALSE,
                    'psgi.multithread'  => Plack::Util::FALSE,
                    'psgi.multiprocess' => $self->{prefork},
                    'psgi.streaming'    => Plack::Util::TRUE,
                    'psgi.nonblocking'  => Plack::Util::FALSE,
                    'psgix.input.buffered' => Plack::Util::TRUE,
                };

                # no need to take care of pipelining since this module is a HTTP/1.0 server
                my $may_keepalive = $req_count < $self->{max_keepalive_reqs};
                if ($may_keepalive && $max_reqs_per_child && $proc_req_count >= $max_reqs_per_child) {
                    $may_keepalive = undef;
                }
                $self->handle_connection($env, $conn, $app, $may_keepalive, $req_count != 1)
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
            $is_keepalive ? $self->{keepalive_timeout} : $self->{timeout},
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
            if (my $cl = $env->{CONTENT_LENGTH}) {
                my $buffer = Plack::TempBuffer->new($cl);
                while ($cl > 0) {
                    my $chunk;
                    if (length $buf) {
                        $chunk = $buf;
                        $buf = '';
                    } else {
                        $self->read_timeout($conn, \$chunk, $cl, 0, $self->{timeout});
                    }
                    $buffer->print($chunk);
                    $cl -= length $chunk;
                }
                $env->{'psgi.input'} = $buffer->rewind;
            } else {
                open my $input, "<", \$buf;
                $env->{'psgi.input'} = $input;
            }

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

    if (ref $res eq 'ARRAY') {
        $self->_handle_response($res, $conn, \$use_keepalive);
    } elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($_[0], $conn, \$use_keepalive);
        });
    } else {
        die "Bad response $res";
    }

    return $use_keepalive;
}

sub _handle_response {
    my($self, $res, $conn, $use_keepalive_r) = @_;

    my @lines = (
        "Date: @{[HTTP::Date::time2str()]}\015\012",
        "Server: $self->{server_software}\015\012",
    );

    Plack::Util::header_iter($res->[1], sub {
        my ($k, $v) = @_;
        if (lc $k eq 'connection') {
            $$use_keepalive_r = undef
                if $$use_keepalive_r && lc $v ne 'keep-alive';
        } else {
            push @lines, "$k: $v\015\012";
        }
    });
    if ($$use_keepalive_r) {
        $$use_keepalive_r = undef
            unless Plack::Util::header_exists($res->[1], 'Content-Length');
    }
    push @lines, "Connection: keep-alive\015\012"
        if $$use_keepalive_r;
    unshift @lines, "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\015\012";
    push @lines, "\015\012";

    $self->write_all($conn, join('', @lines), $self->{timeout})
        or return;

    if (defined $res->[2]) {
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
    } else {
        return Plack::Util::inline_object
            write => sub { $self->write_all($conn, $_[0], $self->{timeout}) },
            close => sub { };
    }
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
        alarm($left + $alarm_interval);
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

1;

__END__

=head1 NAME

HTTP::Server::PSGI - Standalone PSGI compatible HTTP server

=head1 SYNOPSIS

  use HTTP::Server::PSGI;

  my $server = HTTP::Server::PSGI->new(
      host => "127.0.0.1",
      port => 9091,
      timeout => 120,
  );

  $server->run($app);

=head1 DESCRIPTION

HTTP::Server::PSGI is a standalone, single-process and PSGI compatible
HTTP server implementations. It runs reasonably fast and HTTP/1.0 and
Keep-Alive requests are supported.

This server should be great for the development and testig, but might
not be suitable for production.

Some features in HTTP/1.1, notably chunked requests, responses and
pipeline requests are B<NOT> supported yet.

See L<Starman> if you want a multi-process prefork server with some
HTTP/1.1 features support.

=head1 AUTHOR

Kazuho Oku

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Handler::Standalone>

=cut
