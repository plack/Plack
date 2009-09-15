package Plack::Impl::Standalone;
use strict;
use warnings;

use Plack::HTTPParser qw( parse_http_request );
use IO::Socket::INET;
use HTTP::Status;
use List::Util qw(sum);
use Plack::Util;
use Socket qw(IPPROTO_TCP TCP_NODELAY);

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
            $conn->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1) or die $!;
            while (1) {
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

                $self->handle_connection($env, $conn, $app) or last;
            }
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
                # TODO can $conn seek to the begining of body and then set to 'psgi.input'?
                while (length $buf < $env->{CONTENT_LENGTH}) {
                    $conn->sysread($buf, $env->{CONTENT_LENGTH} - length($buf), length($buf));
                }
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

    my (@lines, $has_cl, $conn_value);
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
    if (! $has_cl && ref $res->[2] eq 'ARRAY') {
        unshift @lines, "Content-Length: @{[sum map { length $_ } @{$res->[2]}]}\r\n";
        $has_cl = 1;
    }
    if ($has_cl && ! defined($conn_value) && ($env->{HTTP_CONNECTION} || '') =~ /keep-alive/i) {
        unshift @lines, "Connection: keep-alive\r\n";
        $conn_value = "keep-alive";
    }
    unshift @lines, "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\r\n";
    push @lines, "\r\n";

    $conn->syswrite(join '', @lines);

    if ($HasSendFile && do {
        my $fileno = eval { fileno $res->[2] };
        defined($fileno) && $fileno >= 0;
     }) {
        Sys::Sendfile::sendfile($conn, $res->[2]);
    } else {
        Plack::Util::foreach( $res->[2], sub { $conn->syswrite(@_) } );
    }
    defined($conn_value) && $conn_value =~  /keep-alive/i;
}
