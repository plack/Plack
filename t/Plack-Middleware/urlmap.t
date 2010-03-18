use strict;
use Test::More;
use Plack::App::URLMap;
use Plack::Test;
use HTTP::Request::Common;

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
my $app3 = $make_app->("app3");
my $app4 = $make_app->("app4");

my $app = Plack::App::URLMap->new;
$app->map("/" => $app1);
$app->map("/foo" => $app2);
$app->map("/foobar" => $app3);
$app->map("http://bar.example.com/" => $app4);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res ;

    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app1||/';

    $res = $cb->(GET "http://localhost/foo");
    is $res->content, 'app2|/foo|';

    $res = $cb->(GET "http://localhost/foo/bar");
    is $res->content, 'app2|/foo|/bar';

    $res = $cb->(GET "http://localhost/foox");
    is $res->content, 'app1||/foox';

    $res = $cb->(GET "http://localhost/foox/bar");
    is $res->content, 'app1||/foox/bar';

    $res = $cb->(GET "http://localhost/foobar");
    is $res->content, 'app3|/foobar|';

    $res = $cb->(GET "http://localhost/foobar/baz");
    is $res->content, 'app3|/foobar|/baz';

    $res = $cb->(GET "http://localhost/bar/foo");
    is $res->content, 'app1||/bar/foo';

    $res = $cb->(GET "http://bar.example.com/");
    is $res->content, 'app4||/';

    $res = $cb->(GET "http://bar.example.com/foo");
    is $res->content, 'app4||/foo';

    # Fix a bug where $location eq ''
    $_ = "bar"; /bar/;
    $res = $cb->(GET "http://localhost/");
    is $res->content, 'app1||/';

};

done_testing;
