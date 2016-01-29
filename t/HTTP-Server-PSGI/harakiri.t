use strict;
use warnings;

use Plack::Loader;
use Test::More;
use Test::TCP;
use Test::Requires qw(LWP::UserAgent);

my $ua_timeout = 3;

test_tcp(
    listen => 1,
    server => sub {
        my $socket = shift;
        my $server = Plack::Loader->auto(listen_sock => $socket);
        $server->run(
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
        sleep $ua_timeout + 2; # to block
    },
    client => sub {
        my $port = shift;
        my $ua = LWP::UserAgent->new( timeout => $ua_timeout );
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
