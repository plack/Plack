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
                if ($env->{PATH_INFO} eq '/kill') {
                    $env->{'psgix.harakiri.commit'} = 1;
                }
                return [
                    200,
                    [ 'Content-Type' => 'text/plain' ],
                    [ "Hi" ],
                ];
            },
        );
        sleep 5; # to block
    },
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/");
        ok $res->is_success;
        is $res->code, 200;
        is $res->content, 'Hi';

        $res = $ua->get("http://127.0.0.1:$port/kill");
        ok $res->is_success;
        is $res->code, 200;

        note 'check that the server is dead';
        $res = $ua->get("http://127.0.0.1:$port/");

        ok !$res->is_success, "no response";
    },
);

done_testing;
