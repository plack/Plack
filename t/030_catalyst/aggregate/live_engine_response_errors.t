#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 18;
use Catalyst::Test 'TestApp';

close STDERR;    # i'm naughty :)

{
    ok( my $response = request('http://localhost/engine/response/errors/one'),
        'Request' );
    ok( $response->is_error, 'Response Server Error 5xx' );
    is( $response->code,         500,         'Response Code' );
    is( $response->content_type, 'text/html', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'),
        'engine/response/errors/one', 'Test Action' );
    like(
        $response->header('X-Catalyst-Error'),
        qr/^Caught exception/,
        'Catalyst Error'
    );
}

{
    ok( my $response = request('http://localhost/engine/response/errors/two'),
        'Request' );
    ok( $response->is_error, 'Response Server Error 5xx' );
    is( $response->code,         500,         'Response Code' );
    is( $response->content_type, 'text/html', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'),
        'engine/response/errors/two', 'Test Action' );
    like(
        $response->header('X-Catalyst-Error'),
        qr/^Couldn't forward to/,
        'Catalyst Error'
    );
}

{
    ok( my $response = request('http://localhost/engine/response/errors/three'),
        'Request' );
    ok( $response->is_error, 'Response Server Error 5xx' );
    is( $response->code,         500,         'Response Code' );
    is( $response->content_type, 'text/html', 'Response Content-Type' );
    is(
        $response->header('X-Catalyst-Action'),
        'engine/response/errors/three',
        'Test Action'
    );
    like(
        $response->header('X-Catalyst-Error'),
        qr/I'm going to die!/,
        'Catalyst Error'
    );
}
