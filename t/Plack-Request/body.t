use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    is_deeply $req->body_parameters, { foo => 'bar' };
    is $req->content, 'foo=bar';

    my $b = $req->body_parameters;
    $b->{foo} = 'body-updated';

    my $b2 = $req->body_parameters;
    is ($b2->{foo}, "body-updated", "body parameters are read-write");

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(POST "/", { foo => "bar" });
    ok $res->is_success;
};

done_testing;
