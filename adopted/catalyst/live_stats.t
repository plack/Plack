#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::More;
use Catalyst::Test 'TestAppStats';

if ( $ENV{CATALYST_SERVER} ) {
    plan skip_all => 'Using remote server';
}
else {
    plan tests => 5;
}

{
    ok( my $response = request('http://localhost/'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
}
{
    ok( my $response = request('http://localhost/'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    like( $response->content, qr/\/default.*?[\d.]+s.*- test.*[\d.]+s/s, 'Stats report');

}

