use strict;
use Test::More;
use Plack::App::URLMap;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Auth::Basic;
use Plack::Middleware::AccessLog;

my $app1 = sub {
    my $env = shift;
    return [ 200, ['Content-Type' => 'text/plain'], ["Hello $env->{REMOTE_USER}"] ];
};

$app1 = Plack::Middleware::Auth::Basic->wrap($app1, authenticator => sub { 1 });

my $app = Plack::App::URLMap->new;
$app->map("/foo" => $app1);

my $line;
$app = Plack::Middleware::AccessLog->wrap($app, logger => sub { $line = shift });

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/foo", Authorization => "Basic YWRtaW46czNjcjN0");
    is $res->content, 'Hello admin';

    like $line, qr/ admin /;
};

done_testing;
