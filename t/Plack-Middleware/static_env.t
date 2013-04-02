use strict;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::AccessLog;
use Plack::Middleware::Auth::Basic;
use Plack::Middleware::Static;

my $app = sub {
    my $env = shift;
    return [ 200, ['Content-Type' => 'text/plain'], ["Hello $env->{REMOTE_USER}"] ];
};

$app = Plack::Middleware::Static->wrap($app, path => qr!^/t/!, root => ".");
$app = Plack::Middleware::Auth::Basic->wrap($app, authenticator => sub { 1 });

my $line;
$app = Plack::Middleware::AccessLog->wrap($app, logger => sub { $line = shift });

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/t/test.txt", Authorization => "Basic YWRtaW46czNjcjN0");
    like $res->content, qr/foo/;

    like $line, qr/ admin /;
};

done_testing;
