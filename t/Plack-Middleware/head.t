use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    my $body = "Hello World";
    [ 200, [ 'Content-Type', 'text/plain', 'Content-Length', length($body) ], [ $body ] ];
};

$app = builder { enable "Head"; $app };

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, "Hello World";

    $res = $cb->(HEAD "/");
    ok !$res->content;
    is $res->content_length, 11;
};

done_testing;

