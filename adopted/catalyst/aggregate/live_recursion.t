#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 3;
use Catalyst::Test 'TestApp';

local $^W = 0;

SKIP:
{
    # Net::HTTP::Methods crashes when talking to a remote server because this
    # test causes a very long header line to be sent
    if ( $ENV{CATALYST_SERVER} ) {
        skip 'Using remote server', 3;
    }

    ok( my $response = request('http://localhost/recursion_test'), 'Request' );
    ok( !$response->is_success, 'Response Not Successful' );
    is( $response->header('X-Catalyst-Error'), 'Deep recursion detected calling "/recursion_test"', 'Deep Recursion Detected' );
}

