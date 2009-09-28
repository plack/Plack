use strict;
use warnings;
use Test::Base;
use IO::Scalar;

use t::Utils;

plan tests => 4*blocks;

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
        %$env
    );

    if ($block->nullkey) {
        $block->args->{$block->nullkey} = undef;
    }

    is $req->uri, $block->expected_uri;
    is_deeply $req->query_parameters, $block->expected_params;
    is $req->uri_with( $block->args || {} ), $block->expected;

    tie *STDERR, 'IO::Scalar', \my $out;
    $req->uri_with;
    untie *STDERR;
    like $out, qr/No arguments passed to uri_with()/;
};

__END__

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /
--- expected_uri: http://example.com/
--- expected: http://example.com/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test.c
--- expected_uri: http://example.com/test.c
--- expected: http://example.com/test.c
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test.c
  PATH_INFO: /info
--- expected_uri: http://example.com/test.c/info
--- expected: http://example.com/test.c/info
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test
  QUERY_STRING: dynamic=daikuma
--- expected_uri: http://example.com/test?dynamic=daikuma
--- expected: http://example.com/test?dynamic=daikuma
--- expected_params: { dynamic => 'daikuma' }


===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /exec/
--- expected_uri: http://example.com/exec/
--- expected: http://example.com/exec/
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /////exec/
--- expected_uri: http://example.com/exec/
--- expected: http://example.com/exec/
--- expected_params: {}

===
--- args
--- add_env
  SERVER_NAME: example.com
--- expected_uri: http://example.com/
--- expected: http://example.com/
--- expected_params: {}

===
--- args
--- add_env
--- expected_uri: http:///
--- expected: http:///
--- expected_params: {}

===
--- args
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /
  QUERY_STRING: aco=tie
--- expected: http://example.com/?aco=tie
--- expected_uri: http://example.com/?aco=tie
--- expected_params: { aco => 'tie' }
