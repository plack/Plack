use strict;
use warnings;
use Test::Base;

use t::Utils;

plan tests => 3*blocks;

filters { env  => ['yaml'] };
run {
    my $block = shift;
    my $req = req(env => $block->env);
    my $secure = $req->secure;
    is qq{"$secure"}  , $block->is_secure;
    is $req->uri      , $block->uri;
    is $req->uri->port, $block->port;
}

__END__

===
--- env
  HTTP_HOST: example.com
  psgi.url_scheme: https
  SERVER_PORT: 443
--- is_secure: "1"
--- uri: https://example.com/
--- port: 443

===
--- env
  HTTP_HOST: example.com
  psgi.url_scheme: http
  SERVER_PORT: 80
--- is_secure: "0"
--- uri: http://example.com/
--- port: 80

===
--- env
  HTTP_HOST: example.com
  psgi.url_scheme: http
  SERVER_PORT: 80
--- is_secure: "0"
--- uri: http://example.com/
--- port: 80

===
--- env
  HTTP_HOST: example.com
  SERVER_PORT: 8443
  psgi.url_scheme: https
--- is_secure: "1"
--- uri: https://example.com:8443/
--- port: 8443

===
--- env
  HTTP_HOST: example.com
  SERVER_PORT: 443 
  psgi.url_scheme: https
--- is_secure: "1"
--- uri: https://example.com/
--- port: 443

===
--- env
  HTTP_HOST: example.com
  SERVER_PORT: 80
  psgi.url_scheme: http
--- is_secure: "0"
--- uri: http://example.com/
--- port: 80
