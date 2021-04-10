use strict;
use warnings;
use utf8;
use Test::More;
use HTTP::Request;
use HTTP::Message::PSGI;

my $env = {
    'psgi.multiprocess'    => '',
    'SCRIPT_NAME'          => '',
    'SERVER_NAME'          => 0,
    'PATH_INFO'            => '/foobar',
    'HTTP_ACCEPT'          => '*/*',
    'REQUEST_METHOD'       => 'GET',
    'psgi.multithread'     => '',
    'HTTP_USER_AGENT'      => 'curl/7.24.0 (x86_64-apple-darwin12.0) libcurl/7.24.0 OpenSSL/0.9.8r zlib/1.2.5',
    'QUERY_STRING'         => 'baz=3',
    'REMOTE_PORT'          => 56920,
    'SERVER_PORT'          => 8000,
    'psgix.input.buffered' => 1,
    'REMOTE_ADDR'          => '127.0.0.1',
    'SERVER_PROTOCOL'      => 'HTTP/1.1',
    'psgi.streaming'       => 1,
    'psgi.errors'          => *::STDERR,
    'REQUEST_URI'          => '/foobar?baz=3',
    'psgi.version'         => [ 1, 1 ],
    'psgi.nonblocking'     => '',
    'psgix.io'             => *::STDIN,
    'psgi.url_scheme'      => 'http',
    'psgi.run_once'        => '',
    'psgix.harakiri'       => 1,
    'HTTP_HOST'            => 'localhost:8000',
    'psgi.input'           => *::STDIN,
};

for my $req (req_from_psgi($env), HTTP::Request->from_psgi($env)) {
    isa_ok($req, 'HTTP::Request');
    is($req->method, 'GET');
    is($req->uri, 'http://localhost:8000/foobar?baz=3');
    is($req->header('Accept'), '*/*');
}

my $req = req_from_psgi(HTTP::Request->new('GET', 'http://localhost/', [], 'ok')->to_psgi);
is($req->content, 'ok', 'content works');

done_testing;

