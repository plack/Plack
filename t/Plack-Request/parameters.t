use strict;
use warnings;
use Test::More;
use Plack::Request;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    my $b = $req->body_parameters;
    is $b->{foo}, 'bar';
    my $q = $req->query_parameters;
    is $q->{bar}, 'baz';
    my $h = $req->header_parameters;
    is $h->get('QUX'), 'quux';

    is_deeply $req->parameters, { foo => 'bar', 'bar' => 'baz' };

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(POST "/?bar=baz", QUX => 'quux', Content => [ foo => "bar" ]);
};

done_testing;
