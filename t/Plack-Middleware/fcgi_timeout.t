use strict;
use warnings;
use Test::More;
use Test::Requires { FCGI => 0, 'FCGI::Client' => 0.04 };
use Plack::Handler::FCGI;
use Plack::App::FCGIDispatcher;
use Plack::Test;
use HTTP::Request::Common;
use Test::TCP;

plan skip_all => "Set TEST_FCGI_CLIENT to test this"
    unless $ENV{TEST_FCGI_CLIENT};

my $app = sub {
    my $env = shift;
    sleep 5;
    return [ 200, ["Content-Type", "text/plain"], ["Hello"] ];
};

test_tcp(
    server => sub {
        my $port = shift;
        my $server = Plack::Handler::FCGI->new(
            host        => '127.0.0.1',
            port        => $port,
            manager     => '',
            keep_stderr => 1,
        );
        $server->run($app);
    },
    client => sub {
        my $port = shift;
        my $fcgi_app = Plack::App::FCGIDispatcher->new({
            port => $port,
            timeout => 1,
        });

        test_psgi $fcgi_app, sub {
            my $cb = shift;
            my $res = $cb->(GET "/");
            is $res->code, 502;
        };
    },
);

done_testing;
