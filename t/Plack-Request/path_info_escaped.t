use strict;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;
use Data::Dumper;

my $path_app = sub {
    my $req = Plack::Request->new(shift);
    my $res = $req->new_response(200);
    $res->content_type('text/plain');
    $res->content('my ' . Dumper([ $req->uri, $req->parameters ]));
    return $res->finalize;
};

test_psgi $path_app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/foo.bar-baz?a=b");
    is_deeply eval($res->content), [ URI->new("http://localhost/foo.bar-baz?a=b"), { a => 'b' } ];

    $res = $cb->(GET "http://localhost/foo%2fbar#ab");
    is_deeply eval($res->content), [ URI->new("http://localhost/foo/bar"), {} ],
        "%2f vs / can't be distinguished - that's alright";

    $res = $cb->(GET "http://localhost/%23foo?a=b");
    is_deeply eval($res->content), [ URI->new("http://localhost/%23foo?a=b"), { a => 'b' } ];
};

done_testing;
