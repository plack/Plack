use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    is_deeply $req->query_parameters, { foo => 'bar' };

    my $b = $req->query_parameters;
    $b->{foo} = 'query-updated';

    my $b2 = $req->query_parameters;
    is ($b2->{foo}, "query-updated", "query parameters are read-write");

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/?foo=bar" );
    ok $res->is_success;
};

done_testing;
