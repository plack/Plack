package Plack::Impl::Coro;
use strict;

sub new {
    my $class = shift;
    bless { @_ }, $class;
}

sub run {
    my($self, $app) = @_;

    my $server = Plack::Impl::Coro::Server->new(host => $self->{host} || '*');
    $server->{app} = $app;
    $server->run(port => $self->{port});
}


package Plack::Impl::Coro::Server;
use base qw( Net::Server::Coro );

our $HasAIO = eval "use Coro::AIO; 1";

use HTTP::Status;
use Scalar::Util;
use List::Util qw(sum max);
use Plack::HTTPParser qw( parse_http_request );
use constant MAX_REQUEST_SIZE => 131072;

sub process_request {
    my $self = shift;

    my $fh = $self->{server}{client};

    my $env = {
        SERVER_PORT => $self->{server}{port}[0],
        SERVER_NAME => $self->{server}{host}[0],
        SCRIPT_NAME => '',
        REMOTE_ADDR => $self->{server}{peeraddr},
        'psgi.version' => [ 1, 0 ],
        'psgi.errors'  => *STDERR,
        'psgi.input'   => $self->{server}{client},
        'psgi.url_scheme' => 'http', # SSL support?
        'psgi.run_once'     => Plack::Util::FALSE,
        'psgi.multithread'  => Plack::Util::TRUE,
        'psgi.multiprocess' => Plack::Util::FALSE,
    };

    my $res = [ 400, [ 'Content-Type' => 'text/plain' ], [ 'Bad Request' ] ];

    my $buf = '';
    while (1) {
        $buf .= $fh->readline("\015\012\015\012")
            or last;

        my $reqlen = parse_http_request($buf, $env);
        if ($reqlen >= 0) {
            $res = $self->{app}->($env);
            last;
        } elsif ($reqlen == -2) {
            # incomplete, continue
        } else {
            last;
        }
    }

    my (@lines, $has_cl, $conn_value);

    while (my ($k, $v) = splice(@{$res->[1]}, 0, 2)) {
        push @lines, "$k: $v\015\012";
        if ($k =~ /^(?:(content-length)|(connection))$/i) {
            if ($1) {
                $has_cl = 1;
            } else {
                $conn_value = $v;
            }
        }
    }
    if (! $has_cl && ref $res->[2] eq 'ARRAY') {
        unshift @lines, "Content-Length: @{[sum map { length $_ } @{$res->[2]}]}\015\012";
        $has_cl = 1;
    }

    unshift @lines, "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\015\012";
    push @lines, "\015\012";

    $fh->syswrite(join '', @lines);

    if ($HasAIO && Scalar::Util::reftype $res->[2] eq 'GLOB' && fileno $res->[2] > 0) {
        my $length = -s $res->[2];
        my $offset = 0;
        while (1) {
            my $sent = aio_sendfile( $fh->fh, $res->[2], $offset, $length - $offset );
            $offset += $sent;
            last if $offset >= $length;
        }
        return;
    }

    Plack::Util::foreach($res->[2], sub { $fh->syswrite(@_) });
}

package Plack::Impl::Coro;

1;
