package Plack::Impl::Standalone;
use strict;
use warnings;

use Plack::HTTPParser qw( parse_http_request );
use IO::Socket::INET;
use HTTP::Status;
use Plack::Util;

our $HasSendFile = do {
    local $@;
    eval { require Sys::Sendfile; 1 };
};

my $max_req_size = 131072;

sub new {
    my($class, %args) = @_;
    bless {
        host => $args{host} || 0,
        port => $args{port} || 8080,
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

            $self->handle_connection($env, $conn, $app);
        }
    }
}

sub handle_connection {
    my($self, $env, $conn, $app) = @_;

    my $buf = '';
    my $res = [ 400, [ 'Content-Type' => 'text/plain' ], [ 'Bad Request' ] ];

    while (1) {
        my $rlen = $conn->sysread(
            $buf,
            $max_req_size - length($buf),
            length($buf),
        );
        last if ! defined($rlen) || $rlen <= 0;
        my $reqlen = parse_http_request($buf, $env);
        if ($reqlen >= 0) {
            # handle request
            $buf = substr $buf, $reqlen;
            if ($env->{CONTENT_LENGTH}) {
                warn "content-length: ", $env->{CONTENT_LENGTH};
                $conn->sysread($buf, $env->{CONTENT_LENGTH} - length($buf), length($buf));
            }

            open my $input, "<", \$buf;
            $env->{'psgi.input'} = $input;
            $res = $app->($env);
            last;
        }
        if ($reqlen == -2) {
            # request is incomplete, do nothing
        } elsif ($reqlen == -1) {
            # error, close conn
            last;
        }
    }

    $conn->syswrite("HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\r\n");
    while (my ($k, $v) = splice(@{$res->[1]}, 0, 2)) {
        $conn->syswrite("$k: $v\r\n");
    }
    $conn->syswrite("\r\n");

    if (defined(my $fileno = eval { fileno $res->[2] })) {
        if ($fileno > 0 && $HasSendFile) {
            Sys::Sendfile::sendfile($conn, $res->[2]);
            return;
        }
    }

    Plack::Util::foreach( $res->[2], sub { $conn->syswrite(@_) } );
}
