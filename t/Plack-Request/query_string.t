use strict;
use Test::More;
use Plack::Request;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    return [ 200, [], [ $req->query_string ] ];
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/?foo=bar");
    is $res->content, 'foo=bar';

    $res = $cb->(GET "http://localhost/?foo+bar");
    is $res->content, 'foo+bar';
};

done_testing;
