#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 20*$iters;
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
    # test root index
    {
        my @expected = qw[
          TestApp->index
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
        ok( my $response = request('http://localhost/'), 'root index' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'root index', 'root index ok' );
        
        ok( $response = request('http://localhost'), 'root index no slash' );
        is( $response->content, 'root index', 'root index no slash ok' );
    }
    
    # test first-level controller index
    {
        my @expected = qw[
          TestApp::Controller::Index->index
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
        
        ok( my $response = request('http://localhost/index/'), 'first-level controller index' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'Index index', 'first-level controller index ok' );
        
        ok( $response = request('http://localhost/index'), 'first-level controller index no slash' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'Index index', 'first-level controller index no slash ok' );        
    }    
    
    # test second-level controller index
    {
        my @expected = qw[
          TestApp::Controller::Action::Index->begin
          TestApp::Controller::Action::Index->index
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
        
        ok( my $response = request('http://localhost/action/index/'), 'second-level controller index' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'Action-Index index', 'second-level controller index ok' );
        
        ok( $response = request('http://localhost/action/index'), 'second-level controller index no slash' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'Action-Index index', 'second-level controller index no slash ok' );        
    }
    
    # test controller default when index is present
    {
        my @expected = qw[
          TestApp::Controller::Action::Index->begin
          TestApp::Controller::Action::Index->default
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
        
        ok( my $response = request('http://localhost/action/index/foo'), 'default with index' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, "Error - TestApp::Controller::Action\n", 'default with index ok' );
    }
}
