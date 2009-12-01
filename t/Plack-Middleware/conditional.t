use strict;
no warnings;
use Plack::Test;
use Plack::Builder;
use Test::More;
use HTTP::Request::Common;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello' ] ] };

$app = builder {
    enable_if { $_[0]->{HTTP_X_FOO} =~ /Bar/i }
        'XFramework', framework => 'Testing';
    enable_if { $_[0]->{HTTP_X_ALLCAPS} }
        sub {
            my $app = shift;
            sub { my $res = $app->($_[0]); $res->[2] = [ map uc $_, @{$res->[2]} ]; $res };
        };
    $app;
};

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
