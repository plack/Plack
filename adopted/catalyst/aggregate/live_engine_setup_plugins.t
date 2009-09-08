#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 2;
use Catalyst::Test 'TestApp';

{
  # Allow overriding automatic root.
    ok( my $response = request('http://localhost/engine/response/headers/one'), 'Request' );
    is( $response->header('X-Catalyst-Plugin-Setup'), '1' );
}
