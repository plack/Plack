#!perl

# This tests to make sure the Authorization header is passed through by the engine.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 7;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use HTTP::Headers;
use HTTP::Request::Common;

{
    my $creq;

    my $request = GET(
        'http://localhost/dump/request',
        'Authorization' => 'Basic dGVzdDoxMjM0NQ==',
    );

    ok( my $response = request($request), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    like( $response->content, qr/'Catalyst::Request'/,
        'Content is a serialized Catalyst::Request' );

    {
        no strict 'refs';
        ok(
            eval '$creq = ' . $response->content,
            'Unserialize Catalyst::Request'
        );
    }

    isa_ok( $creq, 'Catalyst::Request' );
    
    is( $creq->header('Authorization'), 'Basic dGVzdDoxMjM0NQ==', 'auth header ok' );
}
