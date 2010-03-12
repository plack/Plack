use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    is $req->content, '';
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    ok $res->is_success or diag $res->content;

    $res = $cb->(HEAD "/");
    ok $res->is_success or diag $res->content;
};

done_testing;
