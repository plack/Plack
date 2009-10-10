use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
};

$app = builder {
    add "Plack::Middleware::SimpleContentFilter",
        filter => sub { s/Foo/Bar/g; };
    $app;
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
    is $res->content, 'Hello Bar';
};

done_testing;

