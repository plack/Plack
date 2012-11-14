use strict;
no warnings;
use Plack::Test;
use Plack::Builder;
use Test::More;
use HTTP::Request::Common;

use Plack::Middleware::Conditional;
use Plack::Middleware::XFramework;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello' ] ] };
my $mw1 = Plack::Middleware::Conditional->new(
    condition => sub { $_[0]->{HTTP_X_FOO} =~ /Bar/i },
    builder   => sub { Plack::Middleware::XFramework->new(framework => 'Testing')->wrap($_[0]) },
);
my $mw2 = Plack::Middleware::Conditional->new(
    condition => sub { $_[0]->{HTTP_X_ALLCAPS} },
    builder   => sub {
        my $app = shift;
        sub { my $res = $app->($_[0]); $res->[2] = [ map uc $_, @{$res->[2]} ]; $res };
    },
);

$app = $mw2->wrap($app);
$app = $mw1->wrap($app);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my($req, $res);

    $req = GET "http://localhost/";
    $res = $cb->($req);
    ok !$res->header('X-Framework');

    $req = GET "http://localhost/", 'X-Foo' => 'Bar';
    $res = $cb->($req);
    like $res->header('X-Framework'), qr/Testing/;

    $req = GET "http://localhost/", 'X-AllCaps' => 1;
    $res = $cb->($req);
    is $res->content, 'HELLO';
};

done_testing;
