#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 1;
use Catalyst::Test 'TestApp';

SKIP:
{
    if ( $ENV{CATALYST_SERVER} ) {
        skip "Using remote server", 1;
    }
    # Allow overriding automatic root.
    is( TestApp->config->{root}, '/some/dir' );
}
