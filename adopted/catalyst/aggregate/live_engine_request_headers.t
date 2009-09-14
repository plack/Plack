#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 18;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use HTTP::Headers;
use HTTP::Request::Common;

TODO: {
    local $TODO = "X-Forwarded-* handling should be done with PSGI middleware";
    my $creq;

    my $request = GET( 'http://localhost/dump/request', 
        'User-Agent'       => 'MyAgen/1.0',
        'X-Whats-Cool'     => 'Catalyst',
        'X-Multiple'       => [ 1 .. 5 ],
        'X-Forwarded-Host' => 'frontend.server.com',
        'X-Forwarded-For'  => '192.168.1.1, 1.2.3.4',
        'X-Forwarded-Port' => 443
    );
 
    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    like( $response->content, qr/bless\( .* 'Catalyst::Request' \)/s, 'Content is a serialized Catalyst::Request' );
    ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
    isa_ok( $creq, 'Catalyst::Request' );
    ok( $creq->secure, 'Forwarded port sets securet' );
    isa_ok( $creq->headers, 'HTTP::Headers', 'Catalyst::Request->headers' );
    is( $creq->header('X-Whats-Cool'), $request->header('X-Whats-Cool'), 'Catalyst::Request->header X-Whats-Cool' );
    
    { # Test that multiple headers are joined as per RFC 2616 4.2 and RFC 3875 4.1.18

        my $excpected = '1, 2, 3, 4, 5';
        my $got       = $creq->header('X-Multiple'); # HTTP::Headers is context sensitive, "force" scalar context

        is( $got, $excpected, 'Multiple message-headers are joined as a comma-separated list' );
    }

    is( $creq->header('User-Agent'), $request->header('User-Agent'), 'Catalyst::Request->header User-Agent' );

    my $host = sprintf( '%s:%d', $request->uri->host, $request->uri->port );
    is( $creq->header('Host'), $host, 'Catalyst::Request->header Host' );

    SKIP:
    {
        if ( $ENV{CATALYST_SERVER} && $ENV{CATALYST_SERVER} !~ /127.0.0.1|localhost/ ) {
            skip "Using remote server", 2;
        }
    
        is( $creq->base->host, 'frontend.server.com', 'Catalyst::Request proxied base' );
        is( $creq->address, '1.2.3.4', 'Catalyst::Request proxied address' );
    }

    SKIP:
    {
        if ( $ENV{CATALYST_SERVER} ) {
            skip "Using remote server", 4;
        }
        # test that we can ignore the proxy support
        TestApp->config->{ignore_frontend_proxy} = 1;
        ok( $response = request($request), 'Request' );
        ok( eval '$creq = ' . $response->content, 'Unserialize Catalyst::Request' );
        is( $creq->base, 'http://localhost/', 'Catalyst::Request non-proxied base' );
        is( $creq->address, '127.0.0.1', 'Catalyst::Request non-proxied address' );
    }
}
