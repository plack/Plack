use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Middleware::Lint;

my @good = map { Plack::Middleware::Lint->wrap($_) } (
    sub {
        my $body = "abc";
        utf8::upgrade($body);
        return [ 200, [ "Content-Type", "text/plain;charset=utf-8"], [ $body ] ];
    },
);

for my $app (@good) {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is $res->code, 200, $res->content;
    };
}

done_testing;
