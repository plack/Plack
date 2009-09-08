#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 38*$iters;
use Catalyst::Test 'TestApp';

use Catalyst::Request;

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
        ok( my $response = request('http://localhost/action/regexp/10/hello'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(\d+)/(\w+)$', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            'Test Class'
        );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
        ok( my $response = request('http://localhost/action/regexp/hello/10'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(\w+)/(\d+)$', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            'Test Class'
        );
        like(
            $response->content,
            qr/^bless\( .* 'Catalyst::Request' \)$/s,
            'Content is a serialized Catalyst::Request'
        );
    }

    {
        ok( my $response = request('http://localhost/action/regexp/mandatory'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(mandatory)(/optional)?$', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            'Test Class'
        );
        my $content = $response->content;
        my $req = eval $content; 

        is( scalar @{ $req->captures }, 2, 'number of captures' );
        is( $req->captures->[ 0 ], 'mandatory', 'mandatory capture' );
        ok( !defined $req->captures->[ 1 ], 'optional capture' );
    }

    {
        ok( my $response = request('http://localhost/action/regexp/mandatory/optional'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/(mandatory)(/optional)?$', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            'Test Class'
        );
        my $content = $response->content;
        my $req = eval $content; 

        is( scalar @{ $req->captures }, 2, 'number of captures' );
        is( $req->captures->[ 0 ], 'mandatory', 'mandatory capture' );
        is( $req->captures->[ 1 ], '/optional', 'optional capture' );
    }

    # test localregex in the root controller
    {
        ok( my $response = request('http://localhost/localregex'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            '^localregex$', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Root',
            'Test Class'
        );
    }
    
    {
        my $url = 'http://localhost/action/regexp/redirect/life/universe/42/everything';
        ok( my $response = request($url),
            'Request' );
        ok( $response->is_redirect, 'Response is redirect' );
        is( $response->header('X-Catalyst-Action'),
            '^action/regexp/redirect/(\w+)/universe/(\d+)/everything$', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Regexp',
            'Test Class'
        );
        my $location = $response->header('location');
        $location =~ s/localhost(:\d+)?/localhost/;
        is(
            $location,
            $url,
            'Redirect URI is the same as the request URI'
        );
    }
}

