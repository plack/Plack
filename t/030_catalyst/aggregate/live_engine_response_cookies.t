#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 15;
use Catalyst::Test 'TestApp';
use HTTP::Headers::Util 'split_header_words';

my $expected = {
    catalyst => [qw|catalyst cool path /bah|],
    cool     => [qw|cool catalyst path /|]
};

{
    ok( my $response = request('http://localhost/engine/response/cookies/one'),
        'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'),
        'engine/response/cookies/one', 'Test Action' );

    my $cookies = {};

    for my $string ( $response->header('Set-Cookie') ) {
        my $cookie = [ split_header_words $string];
        $cookies->{ $cookie->[0]->[0] } = $cookie->[0];
    }

    is_deeply( $cookies, $expected, 'Response Cookies' );
}

{
    ok( my $response = request('http://localhost/engine/response/cookies/two'),
        'Request' );
    ok( $response->is_redirect, 'Response Redirection 3xx' );
    is( $response->code, 302, 'Response Code' );
    is( $response->header('X-Catalyst-Action'),
        'engine/response/cookies/two', 'Test Action' );

    my $cookies = {};

    for my $string ( $response->header('Set-Cookie') ) {
        my $cookie = [ split_header_words $string];
        $cookies->{ $cookie->[0]->[0] } = $cookie->[0];
    }

    is_deeply( $cookies, $expected, 'Response Cookies' );
}

{
    ok( my $response = request('http://localhost/engine/response/cookies/three'),
        'Request' );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content_type, 'text/plain', 'Response Content-Type' );
    is( $response->header('X-Catalyst-Action'),
        'engine/response/cookies/three', 'Test Action' );

    my $cookies = {};

    for my $string ( $response->header('Set-Cookie') ) {
        my $cookie = [ split_header_words $string];
        $cookies->{ $cookie->[0]->[0] } = $cookie->[0];
    }

    is_deeply( $cookies, {
        hash => [ qw(hash a&b&c path /) ],
        this_is_the_real_name => [ qw(this_is_the_real_name foo&bar path /) ], # not "object"
    }, 'Response Cookies' );
}
