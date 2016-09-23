use strict;
use warnings;
use Plack::Builder;
use Test::More;

my $tag  = "Foo";
my $date = "Wed, 23 Sep 2009 13:36:33 GMT";
my $non_matching_date = "Wed, 23 Sep 2009 13:36:32 GMT";

my @tests = (
    {
        app => sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => 'GET' },
        status => 200,
        headers => [ 'Content-Type', 'text/plain' ],
    },
    {
        app => sub { [ 200, [ 'ETag' => $tag, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_NONE_MATCH => $tag },
        status => 304,
        headers => [ ETag => $tag ],
    },
    {
        app => sub { [ 200, [ 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_MODIFIED_SINCE => $date },
        status => 304,
        headers => [ "Last-Modified" => $date ],
    },
    {
        app => sub { [ 200, [ 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_MODIFIED_SINCE => $non_matching_date },
        status => 200,
        headers => [
            "Last-Modified", $date, "Content-Type", "text/plain",
        ],
    },
    {
        app => sub { [ 200, [ 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_MODIFIED_SINCE => "$date; length=2" },
        status => 304,
        headers => [ "Last-Modified", $date ],
    },
    {
        app => sub { [ 200, [ 'ETag' => $tag, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "POST", HTTP_IF_NONE_MATCH => $tag },
        status => 200,
        headers => [ ETag => $tag, 'Content-Type' => "text/plain" ],
    },
    {
        app => sub { [ 200, [ 'ETag' => $tag, 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_NONE_MATCH => $tag,
                 HTTP_IF_MODIFIED_SINCE => $date },
        status => 304,
        headers => [ ETag => $tag, 'Last-Modified' => $date ],
    },
    {
        app => sub { [ 200, [ 'ETag' => $tag, 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_NONE_MATCH => "Bar",
                 HTTP_IF_MODIFIED_SINCE => $date },
        status => 200,
        headers => [ ETag => $tag, 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ],
    },
    {
        app => sub { [ 200, [ 'ETag' => $tag, 'Last-Modified' => $date, 'Content-Type' => 'text/plain' ], [ 'OK' ] ] },
        env => { REQUEST_METHOD => "GET", HTTP_IF_NONE_MATCH => $tag,
                 HTTP_IF_MODIFIED_SINCE => $non_matching_date },
        status => 200,
        headers => [ ETag => $tag,  'Last-Modified' => $date, 'Content-Type' => 'text/plain' ],
    },
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





