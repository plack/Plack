use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;
use Plack::Middleware::Lint;

my @bad = map { Plack::Middleware::Lint->wrap($_) } (
    sub { return {} },
    sub { return [ 200, [], [], [] ] },
    sub { return [ 200, {}, [] ] },
    sub { return [ 0, [], "Hello World" ] },
    sub { return [ 200, [], [ "\x{1234}" ] ] },
    sub { return [ 200, [], {} ] },
    sub { return [ 200, [], undef ] },
    sub { return [ 200, [ "Foo:", "bar" ], [ "Hello" ] ] },
    sub { return [ 200, [ "Foo-", "bar" ], [ "Hello" ] ] },
    sub { return [ 200, [ "0xyz", "bar" ], [ "Hello" ] ] },
    sub { return [ 200, [ "Status", "201" ], [ "Hi" ] ] },
    sub { return [ 200, [ "Foo\nBar", "baz" ], [ '' ] ] },
    sub { return [ 200, [ "Location", "Foo\nBar" ], [] ] },
    sub { return [ 200, [ "Foo" ], [ "Hello" ] ] },
    sub { return sub { shift->([ 200, [], {} ]) } },
    sub { return sub { shift->([ 200, [], undef ]) } },
    sub { return [ 200, [ "X-Foo", undef ], [ "Hi" ] ] },
);

my @good = map { Plack::Middleware::Lint->wrap($_) } (
    sub {
        open my $io, "<", \"foo";
        return [ 200, [ "Content-Type", "text/plain" ], $io ];
    },
    sub {
        my $body = "L\x{e9}on";
        utf8::upgrade $body;
        return [ 200, [ "Content-Type", "text/html; charset=latin-1" ], [ $body ] ];
    },
);

push @bad, builder {
    enable sub { my $app = shift; sub { $_[0]->{SCRIPT_NAME} = '/'; $app->(@_) } };
    enable "Lint";
    $good[0];
};

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
