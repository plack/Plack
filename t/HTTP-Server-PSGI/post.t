use strict;
use warnings;

use Plack::Loader;
use Test::More;
use Test::TCP;
use Test::Requires qw(LWP::UserAgent);

test_tcp(
    listen => 1,
    server => sub {
        my $socket = shift;
        my $server = Plack::Loader->auto(listen_sock => $socket);
        $server->run(
            sub {
                my $env = shift;
                my $buf = '';
                while (length($buf) != $env->{CONTENT_LENGTH}) {
                    my $rlen = $env->{'psgi.input'}->read(
                        $buf,
                        $env->{CONTENT_LENGTH} - length($buf),
                        length($buf),
                    );
                    last unless $rlen > 0;
                }
                return [
                    200,
                    [ 'Content-Type' => 'text/plain' ],
                    [ $buf ],
                ];
            },
        );
    },
    client => sub {
        my $port = shift;
        note 'send a broken request';
        my $sock = IO::Socket::INET->new(
            PeerAddr => "127.0.0.1:$port",
            Proto    => 'tcp',
        ) or die "failed to connect to server:$!";
        $sock->print(<< "EOT");
POST / HTTP/1.0\r
Content-Length: 6\r
\r
EOT
        undef $sock;
        note 'send next request';
        my $ua = LWP::UserAgent->new;
        $ua->timeout(10);
        my $res = $ua->post("http://127.0.0.1:$port/", { a => 1 });
        ok $res->is_success;
        is $res->code, 200;
        is $res->content, 'a=1';
    },
);

done_testing;
