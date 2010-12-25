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

    is_deeply $req->parameters, { foo => 'bar', 'bar' => 'baz' };

    $b->{foo} = 'body-updated';
    $q->{bar} = 'query-updated';

    is_deeply $req->parameters,
        { foo => 'bar', 'bar' => 'baz' },
        "changes to values in the body and query hashes are not reflected in later parameters() calls";

    my $merged = $req->parameters;
    $merged->{foo} = 'body-updated';
    $merged->{bar} = 'query-updated';

    is_deeply $req->parameters,
        { foo => 'body-updated', 'bar' => 'query-updated' },
        "changes to values in the parameters hash *are* reflected in later parameters() calls";

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(POST "/?bar=baz", { foo => "bar" });
};

done_testing;
