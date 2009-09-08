#!perl

# This tests to make sure the REMOTE_USER environment variable is properly passed through by the engine.

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 7;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use HTTP::Request::Common;

{
    my $creq;

    local $ENV{REMOTE_USER} = 'dwc';
    my $request = GET(
        'http://localhost/dump/request',
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
    SKIP:
    {
        if ( $ENV{CATALYST_SERVER} ) {
            skip 'Using remote server', 1;
        }
        is( $creq->remote_user, 'dwc', '$c->req->remote_user ok' );
    }
}
