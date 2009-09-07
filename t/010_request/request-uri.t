use strict;
use warnings;
use Test::Base;
use IO::Scalar;

use t::Utils;

plan tests => 5*blocks;

filters {
    args            => ['yaml'],
    add_env         => ['yaml'],
    expected_params => ['eval'],
};

run {
    my $block = shift;
    my $env = {SERVER_PORT => 80};
    if ($block->add_env && ref($block->add_env) eq 'HASH') {
        while (my($key, $val) = each %{ $block->add_env }) {
            $env->{$key} = $val;
        }
    }
    my $req = req(
        env => $env
    );
    if (defined $block->base) {
        $req->uri(
            do {
                local $_ = $block->base;
                my $uri  = URI->new($_);
                my $base = $uri->path;
                $base =~ s{^/+}{};
                $uri->path($base);
                $base .= '/' unless $base =~ /\/$/;
                $uri->query(undef);
                $uri->path($base);
                URI::WithBase->new( $_, $uri );
            }
        );
    }

    if ($block->nullkey) {
        $block->args->{$block->nullkey} = undef;
    }

    is $req->uri, ($block->base || $block->expected_uri);
    is_deeply $req->query_parameters, $block->expected_params;
    is $req->uri_with( $block->args || {} ), $block->expected;
    is $req->base, $block->expected_base;

    tie *STDERR, 'IO::Scalar', \my $out;
    $req->uri_with;
    untie *STDERR;
    like $out, qr/No arguments passed to uri_with()/;
};

__END__

===
--- base: http://example.com/
--- args
--- expected: http://example.com/
--- expected_base: http://example.com/
--- expected_params: {}

===
--- base: http://example.com
--- args
--- expected: http://example.com
--- expected_base: http://example.com/
--- expected_params: {}

===
--- base: http://example.com/
--- args
  foo: bar
--- expected: http://example.com/?foo=bar
--- expected_base: http://example.com/
--- expected_params: {}

===
--- base: http://example.com/
--- args
  bar: hoge
--- nullkey: bar
--- expected: http://example.com/?bar=
--- expected_base: http://example.com/
--- expected_params: {}

===
--- base: http://example.com/exit/
--- args
  foo: bar
--- expected: http://example.com/exit/?foo=bar
--- expected_base: http://example.com/exit/
--- expected_params: {}

===
--- base: http://example.com/sample
--- args
  foo: bar
--- expected: http://example.com/sample?foo=bar
--- expected_base: http://example.com/sample/
--- expected_params: {}

===
--- base: http://example.com/
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?foo=bar&foo=baz
--- expected_base: http://example.com/
--- expected_params: {}

===
--- base: http://example.com/?aco=tie
--- args
  foo: bar
--- expected: http://example.com/?aco=tie&foo=bar
--- expected_base: http://example.com/
--- expected_params: { aco => 'tie' }

===
--- base: http://example.com/?aco=tie
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&foo=bar&foo=baz
--- expected_base: http://example.com/
--- expected_params: { aco => 'tie' }

===
--- base: http://example.com/?aco=tie&bar=baz
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&bar=baz&foo=bar&foo=baz
--- expected_base: http://example.com/
--- expected_params: { aco => 'tie', bar => 'baz' }

===
--- base: http://example.com/?aco=tie&bar=baz&bar=foo
--- args
  foo:
    - bar
    - baz
--- expected: http://example.com/?aco=tie&bar=baz&bar=foo&foo=bar&foo=baz
--- expected_base: http://example.com/
--- expected_params: { aco => 'tie', bar => [ 'baz', 'foo' ] }

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /
--- expected_uri: http://example.com/
--- expected: http://example.com/
--- expected_base: http://example.com/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test.c
--- expected_uri: http://example.com/test.c
--- expected: http://example.com/test.c
--- expected_base: http://example.com/test.c/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test.c
  PATH_INFO: /info
--- expected_uri: http://example.com/test.c/info
--- expected: http://example.com/test.c/info
--- expected_base: http://example.com/test.c/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  REDIRECT_URL: /redirect
  SCRIPT_NAME: /test
--- expected_uri: http://example.com/redirect
--- expected: http://example.com/redirect
--- expected_base: http://example.com/redirect/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  REDIRECT_URL: /redirect
  SCRIPT_NAME: /test
  PATH_INFO: /info
--- expected_uri: http://example.com/redirect/info
--- expected: http://example.com/redirect/info
--- expected_base: http://example.com/redirect/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test
  QUERY_STRING: dynamic=daikuma
--- expected_uri: http://example.com/test?dynamic=daikuma
--- expected: http://example.com/test?dynamic=daikuma
--- expected_base: http://example.com/test/
--- expected_params: { dynamic => 'daikuma' }


===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /exec/
--- expected_uri: http://example.com/exec/
--- expected: http://example.com/exec/
--- expected_base: http://example.com/exec/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /////exec/
--- expected_uri: http://example.com/exec/
--- expected: http://example.com/exec/
--- expected_base: http://example.com/exec/
--- expected_params: {}

===
--- args
--- add_env
  SERVER_NAME: example.com
--- expected_uri: http://example.com/
--- expected: http://example.com/
--- expected_base: http://example.com/
--- expected_params: {}

===
--- args
--- add_env
--- expected_uri: http:///
--- expected: http:///
--- expected_base: http:///
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /
  QUERY_STRING: aco=tie
--- expected: http://example.com/?aco=tie
--- expected_uri: http://example.com/?aco=tie
--- expected_base: http://example.com/
--- expected_params: { aco => 'tie' }
