use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => 9 ], [ 'Hello ', 'Foo' ] ];
};

$app = builder {
    enable "ContentLength";
    enable "SimpleContentFilter",
        filter => sub { s/Foo/FooBar/g; };
    $app;
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
    is $res->content, 'Hello FooBar';
    is $res->content_length, 12;
};

done_testing;

