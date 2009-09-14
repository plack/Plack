#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 34*$iters;
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
        ok( my $response = request('http://localhost/action/local/one'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/local/one', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Local',
            'Test Class'
        );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
        ok( my $response = request('http://localhost/action/local/two/1/2'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/local/two', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Local',
            'Test Class'
        );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
         ok( my $response = request('http://localhost/action/local/two'),
               'Request' );
         ok( !$response->is_success, 'Request with wrong number of args failed' );
    }

    {
        ok( my $response = request('http://localhost/action/local/three'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/local/three', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Local',
            'Test Class'
        );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
        ok(
            my $response =
              request('http://localhost/action/local/four/five/six'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/local/four/five/six', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Local',
            'Test Class'
        );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    SKIP:
    { 
        if ( $ENV{CATALYST_SERVER} ) {
            skip "tests for %2F on remote server", 6;
        }
        
        ok(
            my $response =
              request('http://localhost/action/local/one/foo%2Fbar'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/local/one', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Local',
            'Test Class'
        );
        like(
            $response->content,
            qr~arguments => \[\s*'foo/bar'\s*\]~,
            "Parameters don't split on %2F"
        );
    }

    {
        ok( my $content = get('http://locahost/action/local/five/foo%2Fbar%3B'),
            'request with URI-encoded arg');
        # this is the CURRENT behavior
        like( $content, qr{'foo/bar;'}, 'args for Local actions URI-decoded' );
    }
}
