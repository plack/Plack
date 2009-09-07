use strict;
use Test::More;
use Plack::Request;

my $env = {
    REQUEST_METHOD    => 'GET',
    SERVER_PROTOCOL   => 'HTTP/1.1',
    SERVER_PORT       => 80,
    SERVER_NAME       => 'example.com',
    SCRIPT_NAME       => '/foo',
    REMOTE_ADDR       => '127.0.0.1',
    'psgi.version'    => [ 1, 0 ],
    'psgi.input'      => undef,
    'psgi.errors'     => undef,
    'psgi.url_scheme' => 'http',
};

my $req = Plack::Request->new( $env );

isa_ok($req, 'Plack::Request');

is($req->address, '127.0.0.1', 'address');
is($req->method, 'GET', 'method');
is($req->protocol, 'HTTP/1.1', 'protocol');
is($req->uri, 'http://example.com/foo', 'uri');
is($req->port, 80, 'port');
ok(!!!$req->secure, 'secure');

done_testing();
