#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use vars qw/
    $EXPECTED_ENV_VAR
    $EXPECTED_ENV_VAL
/;

BEGIN {
    $EXPECTED_ENV_VAR = "CATALYSTTEST$$"; # has to be uppercase otherwise fails on Win32 
    $EXPECTED_ENV_VAL = $ENV{$EXPECTED_ENV_VAR}
         = "Test env value " . rand(100000);
}

use Test::More tests => 6;
use Catalyst::Test 'TestApp';

use Catalyst::Request;
use HTTP::Headers;
use HTTP::Request::Common;

{
    my $env;

    ok( my $response = request("http://localhost/dump/env"),
        'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    ok( eval '$env = ' . $response->content, 'Unserialize Catalyst::Request' );
    is ref($env), 'HASH';
#    ok exists($env->{PATH}), 'Have a PATH env var';

    SKIP:
    {
        if ( $ENV{CATALYST_SERVER} ) {
            skip 'Using remote server', 1;
        }
        is $env->{$EXPECTED_ENV_VAR}, $EXPECTED_ENV_VAL,
            'Value we set as expected';
    }
}

