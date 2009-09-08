#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 24*$iters;
use Catalyst::Test 'TestApp';

if ( $ENV{CAT_BENCHMARK} ) {
    require Benchmark;
    Benchmark::timethis( $iters, \&run_tests );
}
else {
    for ( 1 .. $iters ) {
        run_tests();
    }
}

sub run_tests {
    {
        ok( my $response = request('http://localhost/action/private/one'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Private',
            'Test Class'
        );
        is( $response->content, 'access denied', 'Access' );
    }

    {
        ok( my $response = request('http://localhost/action/private/two'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Private',
            'Test Class'
        );
        is( $response->content, 'access denied', 'Access' );
    }

    {
        ok( my $response = request('http://localhost/three'), 'Request' );
        ok( $response->is_error, 'Response Server Error 5xx' );
        is( $response->content_type, 'text/html', 'Response Content-Type' );
        like(
            $response->header('X-Catalyst-Error'),
            qr/^Unknown resource "three"/,
            'Catalyst Error'
        );
    }

    {
        ok( my $response = request('http://localhost/action/private/four'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Private',
            'Test Class'
        );
        is( $response->content, 'access denied', 'Access' );
    }

    {
        ok( my $response = request('http://localhost/action/private/five'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Private',
            'Test Class'
        );
        is( $response->content, 'access denied', 'Access' );
    }
}
