use strict;
use warnings;
use Test::Base;
use Plack::Request;

plan tests => 2*blocks;

filters {
    add_env    => ['yaml'],
    parameters => ['eval'],
};

run {
    my $block = shift;
    my $env = {SERVER_PORT => 80};
    if ($block->add_env && ref($block->add_env) eq 'HASH') {
        while (my($key, $val) = each %{ $block->add_env }) {
            $env->{$key} = $val;
        }
    }
    my $req = Plack::Request->new($env);

    is $req->uri, $block->uri;
    is_deeply $req->query_parameters, $block->parameters;
};

__END__

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: ""
--- uri: http://example.com/
--- parameters: {}

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: ""
  PATH_INFO: "/foo bar"
--- uri: http://example.com/foo%20bar
--- parameters: {}

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test.c
--- uri: http://example.com/test.c
--- parameters: {}

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test.c
  PATH_INFO: /info
--- uri: http://example.com/test.c/info
--- parameters: {}

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /test
  QUERY_STRING: dynamic=daikuma
--- uri: http://example.com/test?dynamic=daikuma
--- parameters: { dynamic => 'daikuma' }


===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: /exec/
--- uri: http://example.com/exec/
--- parameters: {}

===
--- add_env
  SERVER_NAME: example.com
--- uri: http://example.com/
--- parameters: {}

===
--- add_env
--- uri: http:///
--- parameters: {}

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: ""
  QUERY_STRING: aco=tie
--- uri: http://example.com/?aco=tie
--- parameters: { aco => 'tie' }

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: ""
  QUERY_STRING: 0
--- uri: http://example.com/?0
--- parameters: {}

===
--- add_env
  HTTP_HOST: example.com
  SCRIPT_NAME: "/foo bar"
  PATH_INFO: "/baz quux"
--- uri: http://example.com/foo%20bar/baz%20quux
--- parameters: {}
