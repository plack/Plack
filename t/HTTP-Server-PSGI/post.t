use strict;
use warnings;

use LWP::UserAgent;
use Plack::Runner;
use Test::More;
use Test::TCP;

test_tcp(
    server => sub {
        my $port = shift;
        my $runner = Plack::Runner->new;
        $runner->parse_options("--port" => $port, "-E", "dev", "-s", "HTTP::Server::PSGI");
        $runner->run(
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
                return $env->{PATH_INFO} =~ m[^/_KILL] 
                  ? [ 200,
                      [ 'Content-Type' => 'text/plain',
                        'harakiri.commit'  => 1],
                      [ "sorry, dude, this was your last request" ]
                    ]
                  : [
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

        note 'send kill request';
        $res = $ua->post("http://127.0.0.1:$port/_KILL", { a => 1 });
        ok $res->is_success, "got response";
        is $res->code, 200, "response OK";
        like $res->content, qr/last request/, "was last request";

        note 'check that the server is dead';
        $res = $ua->post("http://127.0.0.1:$port/", { a => 1 });
        ok !$res->is_success, "no response";
    },
);

done_testing;
