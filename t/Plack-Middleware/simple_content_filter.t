use strict;
use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Middleware qw(SimpleContentFilter);

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
};

$app = builder {
    enable Plack::Middleware::SimpleContentFilter
        filter => sub { s/Foo/Bar/g; };
    $app;
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(HTTP::Request->new(GET => 'http://localhost/'));
    is $res->content, 'Hello Bar';
};

done_testing;

