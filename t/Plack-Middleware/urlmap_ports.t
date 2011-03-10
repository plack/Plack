use strict;
use Test::More;
use Plack::App::URLMap;
use Plack::Test;
use HTTP::Request::Common;

$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $make_app = sub {
    my $name = shift;
    sub {
        my $env = shift;
        my $body = join "|", $name, $env->{SCRIPT_NAME}, $env->{PATH_INFO};
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
    };
};

my $app1 = $make_app->("app1");
my $app2 = $make_app->("app2");

my $app = Plack::App::URLMap->new;
$app->map("http://127.0.0.1/" => $app1);
$app->map("/" => $app2);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res;
    $res = $cb->(GET "http://127.0.0.1/");
    is $res->content, 'app1||/';
};

done_testing;
