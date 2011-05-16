use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Middleware::Lint;

my @bad = map { Plack::Middleware::Lint->wrap($_) } (
    sub { return {} },
    sub { return [ 200, [], [], [] ] },
    sub { return [ 200, {}, [] ] },
    sub { return [ 0, [], "Hello World" ] },
    sub { return [ 200, [], [ "\x{1234}" ] ] },
    sub { return [ 200, [], {} ] },
    sub { return [ 200, [], undef ] },
    sub { return sub { shift->([ 200, [], {} ]) } },
    sub { return sub { shift->([ 200, [], undef ]) } },
);

my @good = map { Plack::Middleware::Lint->wrap($_) } (
    sub {
        open my $io, "<", \"foo";
        return [ 200, [ "Content-Type", "text/plain" ], $io ];
    },
);

for my $app (@bad) {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is $res->code, 500, $res->content;
    };
}

for my $app (@good) {
    test_psgi $app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        is $res->code, 200, $res->content;
    };
}

done_testing;
