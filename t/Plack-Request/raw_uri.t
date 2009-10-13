use strict;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $raw_uri;

my $app = sub {
    my $req = Plack::Request->new(shift);
    $raw_uri = $req->raw_uri;
    return [ 200, [], [] ];
};

test_psgi app => $app, client => sub {
    my $cb = shift;

    $cb->(GET "http://localhost/foo%20bar");
    is $raw_uri, 'http://localhost/foo%20bar';

    $cb->(GET "http://localhost:2020/FOO/bar,baz");
    is $raw_uri, 'http://localhost:2020/FOO/bar,baz';
};

done_testing;
