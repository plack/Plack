use strict;
use Test::Base;
use Plack::Builder;

filters {
    app => 'eval',
    env => 'yaml',
    headers => 'yaml',
};

plan tests => 1 * blocks;

run {
    my $block = shift;
    my $handler = builder {
        add "Plack::Middleware::ContentLength";
        $block->app;
    };
    my $res = $handler->($block->env);
    is_deeply $res->[1], $block->headers;
};

__END__

=== 200 response
--- app
sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] }
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- text/plain
- Content-Length
- 2

=== 200 response with filehandle
--- app
sub {
    open my $fh, "<", "share/kyoto.jpg";
    [ 200, [ 'Content-Type' => 'image/jpeg' ], $fh ];
}
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- image/jpeg
- Content-Length
- 2397701

=== 304 no entity header
--- app
sub {
    [ 304, [ ETag => 'Foo' ], [] ];
}
--- env
REQUEST_METHOD: GET
--- headers
- ETag
- Foo

=== 200 not calculatable
--- app
sub {
    my $body = "Hello World";
    open my $fh, "<", \$body;
    [ 200, [ 'Content-Type' => 'text/plain' ], $fh ];
}
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- text/plain

=== 200 with C-L
--- app
sub {
    [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length' => 11 ], [ "Hello World" ] ];
}
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- text/plain
- Content-Length
- 11
