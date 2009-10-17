use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;

my $json = '{"foo":"bar"}';

my $app = sub {
    return [ 200, [ 'Content-Type' => 'application/json' ], [ $json ] ];
};

$app = builder {
    enable "Plack::Middleware::JSONP";
    $app;
};

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
    is $res->content_type, 'application/json';
    is $res->content, $json;
    $res = $cb->(HTTP::Request->new(GET => 'http://localhost/?callback=foo'));
    is $res->content_type, 'text/javascript';
    is $res->content, "foo($json)";
};

done_testing;

