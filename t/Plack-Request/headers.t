use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $headers = $req->header_parameters;
    is $headers->get('X-PLACK-REQUEST-HEADER-TEST'), 'foo';
    is $req->header('X-PLACK-REQUEST-HEADER-TEST'), 'foo';
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/", 'X-PLACK-REQUEST-HEADER-TEST' => 'foo');
    ok $res->is_success;
};

done_testing;
