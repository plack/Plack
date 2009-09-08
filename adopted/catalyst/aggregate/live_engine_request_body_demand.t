#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 12;
use Catalyst::Test 'TestAppOnDemand';

use Catalyst::Request;
use HTTP::Headers;
use HTTP::Request::Common;

# Test a simple POST request to make sure body parsing
# works in on-demand mode.
SKIP:
{
    if ( $ENV{CATALYST_SERVER} ) {
        skip "Using remote server", 12;
    }

    {
        my $params;

        my $request = POST(
            'http://localhost/body/query_params?wibble=wobble',
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => 'foo=bar&baz=quux'
        );

        my $expected = { wibble => 'wobble' };

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );

        {
            no strict 'refs';
            ok(
                eval '$params = ' . $response->content,
                'Unserialize params'
            );
        }

        is_deeply( $params, $expected, 'Catalyst::Request query parameters' );
    }

    {
        my $params;

        my $request = POST(
            'http://localhost/body/params?wibble=wobble',
            'Content-Type' => 'application/x-www-form-urlencoded',
            'Content'      => 'foo=bar&baz=quux'
        );
    
        my $expected = { foo => 'bar', baz => 'quux', wibble => 'wobble' };

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );

        {
            no strict 'refs';
            ok(
                eval '$params = ' . $response->content,
                'Unserialize params'
            );
        }

        is_deeply( $params, $expected, 'Catalyst::Request body and query parameters' );
    }

    # Test reading chunks of the request body using $c->read
    {
        my $creq;
    
        my $request = POST(
            'http://localhost/body/read',
            'Content-Type' => 'text/plain',
            'Content'      => 'x' x 105_000
        );
    
        my $expected = '10000|10000|10000|10000|10000|10000|10000|10000|10000|10000|5000';

        ok( my $response = request($request), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->content, $expected, 'Response Content' );
    }
}
