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
    
    # new dispatcher:
    # 11 wallclock secs (10.14 usr +  0.20 sys = 10.34 CPU) @ 15.18/s (n=157)
    # old dispatcher (r1486):
    # 11 wallclock secs (10.34 usr +  0.20 sys = 10.54 CPU) @ 13.76/s (n=145)
}
else {
    for ( 1 .. $iters ) {
        run_tests();
    }
}
    
sub run_tests {
    # test auto + local method
    {
        my @expected = qw[
          TestApp::Controller::Action::Auto->begin
          TestApp::Controller::Action::Auto->auto
          TestApp::Controller::Action::Auto->one
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
    
        ok( my $response = request('http://localhost/action/auto/one'), 'auto + local' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'one', 'Content OK' );
    }
    
    # test auto + default
    {
        my @expected = qw[
          TestApp::Controller::Action::Auto->begin
          TestApp::Controller::Action::Auto->auto
          TestApp::Controller::Action::Auto->default
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
    
        ok( my $response = request('http://localhost/action/auto/anything'), 'auto + default' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'default', 'Content OK' );
    }
    
    # test auto + auto + local
    {
        my @expected = qw[
          TestApp::Controller::Action::Auto::Deep->begin
          TestApp::Controller::Action::Auto->auto
          TestApp::Controller::Action::Auto::Deep->auto
          TestApp::Controller::Action::Auto::Deep->one
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
    
        ok( my $response = request('http://localhost/action/auto/deep/one'), 'auto + auto + local' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'deep one', 'Content OK' );
    }
    
    # test auto + auto + default
    {
        my @expected = qw[
          TestApp::Controller::Action::Auto::Deep->begin
          TestApp::Controller::Action::Auto->auto
          TestApp::Controller::Action::Auto::Deep->auto
          TestApp::Controller::Action::Auto::Deep->default
          TestApp->end
        ];
    
        my $expected = join( ", ", @expected );
    
        ok( my $response = request('http://localhost/action/auto/deep/anything'), 'auto + auto + default' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'deep default', 'Content OK' );
    }
    
    # test auto + failing auto + local + end
    {
        my @expected = qw[
          TestApp::Controller::Action::Auto::Abort->begin
          TestApp::Controller::Action::Auto->auto
          TestApp::Controller::Action::Auto::Abort->auto
          TestApp::Controller::Action::Auto::Abort->end
        ];
    
        my $expected = join( ", ", @expected );
    
        ok( my $response = request('http://localhost/action/auto/abort/one'), 'auto + failing auto + local' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'abort end', 'Content OK' );
    }
    
    # test auto + default (bug on invocation of default twice)
    {
        my @expected = qw[
          TestApp::Controller::Action::Auto::Default->begin
          TestApp::Controller::Action::Auto->auto
          TestApp::Controller::Action::Auto::Default->auto
          TestApp::Controller::Action::Auto::Default->default
          TestApp::Controller::Action::Auto::Default->end
        ];
    
        my $expected = join( ", ", @expected );
    
        ok( my $response = request('http://localhost/action/auto/default/moose'), 'auto + default' );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        is( $response->content, 'default (auto: 1)', 'Content OK' );
    }
}
