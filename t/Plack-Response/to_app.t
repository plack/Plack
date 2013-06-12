use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Response;

my $res = Plack::Response->new(200);
$res->body("hello");

test_psgi $res->to_app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200, 'response code';
    is $res->content, 'hello', 'content';
};

done_testing;
