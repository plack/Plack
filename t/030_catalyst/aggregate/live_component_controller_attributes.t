#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 4;
use Catalyst::Test 'TestApp';

ok( my $response = request('http://localhost/attributes/view'),
    'get /attributes/view' );
ok( !$response->is_success, 'Response Unsuccessful' );

ok( $response = request('http://localhost/attributes/foo'),
    "get /attributes/foo" );

ok( $response->is_success, "Response OK" );
