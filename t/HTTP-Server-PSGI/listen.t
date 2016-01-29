use strict;
use warnings;

use HTTP::Server::PSGI;
use Test::More;
use Test::TCP;
use Test::Requires qw(LWP::UserAgent);

my $ua_timeout = 3;

test_tcp(
    listen => 1,
    server => sub {
        my $socket = shift;
        my $server = HTTP::Server::PSGI->new(
            listen_sock => $socket,
        );
        $server->run(
            sub {
                my $env = shift;
                return [
                    200,
                    [ 'Content-Type' => 'text/plain' ],
                    [ "Hi" ],
                ];
            },
        );
    },
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new;
        my $res = $ua->get("http://127.0.0.1:$port/");
        ok $res->is_success;
        is $res->code, 200;
        is $res->content, 'Hi';
    },
);

done_testing;
