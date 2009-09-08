#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 18*$iters;
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
        my @expected = qw[
          TestApp::Controller::Action::Detach->begin
          TestApp::Controller::Action::Detach->one
          TestApp::Controller::Action::Detach->two
          TestApp::View::Dump::Request->process
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        # Test detach to chain of actions.
        ok( my $response = request('http://localhost/action/detach/one'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/detach/one', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Detach',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
    }

    {
        my @expected = qw[
          TestApp::Controller::Action::Detach->begin
          TestApp::Controller::Action::Detach->path
          TestApp::Controller::Action::Detach->two
          TestApp::View::Dump::Request->process
          TestApp->end
        ];

        my $expected = join( ", ", @expected );

        # Test detach to chain of actions.
        ok( my $response = request('http://localhost/action/detach/path'),
            'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'),
            'action/detach/path', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::Detach',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
    }

    {
        ok(
            my $response =
              request('http://localhost/action/detach/with_args/old'),
            'Request with args'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'new' );
    }

    {
        ok(
            my $response = request(
                'http://localhost/action/detach/with_method_and_args/old'),
            'Request with args and method'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content, 'new' );
    }
}
