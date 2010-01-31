use strict;
use warnings;
use Plack::Builder;
use Test::More;

my @tests = (
    {
        app => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => 'GET' },
        status => 200,
        headers => [ 'Content-Type', 'text/plain' ],
    },
    {
        app => sub { [ 200, [ 'ETag' => 'Foo', 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_NONE_MATCH => "Foo" },
        status => 304,
        headers => [ ETag => 'Foo' ],
    },
    {
        app => sub { [ 200, [ 'Last-Modified' => 'Wed, 23 Sep 2009 13:36:33 GMT', 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_MODIFIED_SINCE => "Wed, 23 Sep 2009 13:36:33 GMT" },
        status => 304,
        headers => [ "Last-Modified" => "Wed, 23 Sep 2009 13:36:33 GMT" ],
    },
    {
        app => sub { [ 200, [ 'Last-Modified' => 'Wed, 23 Sep 2009 13:36:33 GMT', 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_MODIFIED_SINCE => "Wed, 23 Sep 2009 13:36:32 GMT" },
        status => 200,
        headers => [
            "Last-Modified", "Wed, 23 Sep 2009 13:36:33 GMT", "Content-Type", "text/plain",
        ],
    },
    {
        app => sub { [ 200, [ 'Last-Modified' => 'Wed, 23 Sep 2009 13:36:33 GMT', 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_MODIFIED_SINCE => "Wed, 23 Sep 2009 13:36:33 GMT; length=2" },
        status => 304,
        headers => [ "Last-Modified", "Wed, 23 Sep 2009 13:36:33 GMT" ],
    },
    {
        app => sub { [ 200, [ 'ETag' => 'Foo', 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "POST", HTTP_IF_NONE_MATCH => "Foo" },
        status => 200,
        headers => [ ETag => "Foo", "Content-Type" => "text/plain" ],
    }
);

plan tests => 2*@tests;

for my $block (@tests) {
    my $handler = builder {
        enable "Plack::Middleware::ConditionalGET";
        $block->{app};
    };
    my $res = $handler->($block->{env});
    is $res->[0], $block->{status};
    is_deeply $res->[1], $block->{headers};
}





