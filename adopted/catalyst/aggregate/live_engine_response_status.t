#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 30;
use Catalyst::Test 'TestApp';

{
    ok( my $response = request('http://localhost/engine/response/status/s200'), 'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->code, 200, 'Response Code' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'), 'engine/response/status/s200', 'Test Action' );
    like( $response->content, qr/^200/, 'Response Content' );
}

{
    ok( my $response = request('http://localhost/engine/response/status/s400'), 'Request' );
    ok( $response->is_error, 'Response Client Error 4xx' );
    is( $response->code, 400, 'Response Code' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'), 'engine/response/status/s400', 'Test Action' );
    like( $response->content, qr/^400/, 'Response Content' );
}

{
    ok( my $response = request('http://localhost/engine/response/status/s403'), 'Request' );
    ok( $response->is_error, 'Response Client Error 4xx' );
    is( $response->code, 403, 'Response Code' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'), 'engine/response/status/s403', 'Test Action' );
    like( $response->content, qr/^403/, 'Response Content' );
}

{
    ok( my $response = request('http://localhost/engine/response/status/s404'), 'Request' );
    ok( $response->is_error, 'Response Client Error 4xx' );
    is( $response->code, 404, 'Response Code' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'), 'engine/response/status/s404', 'Test Action' );
    like( $response->content, qr/^404/, 'Response Content' );
}

{
    ok( my $response = request('http://localhost/engine/response/status/s500'), 'Request' );
    ok( $response->is_error, 'Response Server Error 5xx' );
    is( $response->code, 500, 'Response Code' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'), 'engine/response/status/s500', 'Test Action' );
    like( $response->content, qr/^500/, 'Response Content' );
}
