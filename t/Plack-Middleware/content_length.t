use strict;
use Test::More;
use Plack::Builder;

my @tests = (
    {
        app => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => 'GET' },
        headers=> [ 'Content-Type' => 'text/plain', 'Content-Length' => 2 ],
    },
    {
        app => sub {
            open my $fh, "<", "share/baybridge.jpg";
            [ 200, [ 'Content-Type' => 'image/jpeg' ], $fh ];
        },
        env => { REQUEST_METHOD => 'GET' },
        headers => [ 'Content-Type' => 'image/jpeg', 'Content-Length' => 14750 ],
    },
    {
        app => sub {
            [ 304, [ ETag => 'Foo' ], [] ];
        },
        env => { REQUEST_METHOD => 'GET' },
        headers => [ ETag => 'Foo' ],
    },
    {
        app => sub {
            my $body = "Hello World";
            open my $fh, "<", \$body;
            [ 200, [ 'Content-Type' => 'text/plain' ], $fh ];
        },
        env => { REQUEST_METHOD => 'GET' },
        headers => [ 'Content-Type' => 'text/plain' ],
    },
    {
        app => sub {
            [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => 11 ], [ "Hello World" ] ];
        },
        env => { REQUEST_METHOD => 'GET' },
        headers => [ 'Content-Type' => 'text/plain', 'Content-Length', 11 ],
    },
);

plan tests => 1 * @tests;

for my $block (@tests) {
    my $handler = builder {
        enable "Plack::Middleware::ContentLength";
        $block->{app};
    };
    my $res = $handler->($block->{env});
    is_deeply $res->[1], $block->{headers};
};
