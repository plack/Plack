use strict;
use warnings;
use Test::Base;
use Plack::Request;

plan tests => 1*blocks;

run {
    my $block = shift;
    my $env = {
        'psgi.url_scheme' => $block->scheme || 'http',
        HTTP_HOST => $block->host || undef,
        SERVER_NAME => $block->server_name || undef,
        SERVER_PORT => $block->server_port || undef,
        SCRIPT_NAME => $block->script_name || '',
    };

    my $req = Plack::Request->new($env);
    is $req->base, $block->base;
};

__END__

===
--- script_name:
--- host: localhost
--- base: http://localhost/

===
--- script_name: /foo
--- host: localhost
--- base: http://localhost/foo

===
--- script_name: /foo bar
--- host: localhost
--- base: http://localhost/foo%20bar

===
--- scheme: http
--- host: localhost:91
--- base: http://localhost:91/

===
--- scheme: http
--- host: example.com
--- base: http://example.com/

===
--- scheme: https
--- host: example.com
--- base: https://example.com/

===
--- scheme: http
--- server_name: example.com
--- server_port: 80
--- base: http://example.com/

===
--- scheme: http
--- server_name: example.com
--- server_port: 8080
--- base: http://example.com:8080/

===
--- host: foobar.com
--- server_name: example.com
--- server_port: 8080
--- base: http://foobar.com/

