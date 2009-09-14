#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 7*$iters;
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
          TestApp::Controller::Action::End->begin
          TestApp::Controller::Action::End->default
          TestApp::View::Dump::Request->process
          TestApp::Controller::Action::End->end
        ];

        my $expected = join( ", ", @expected );

        ok( my $response = request('http://localhost/action/end'), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->header('X-Catalyst-Action'), 'default', 'Test Action' );
        is(
            $response->header('X-Test-Class'),
            'TestApp::Controller::Action::End',
            'Test Class'
        );
        is( $response->header('X-Catalyst-Executed'),
            $expected, 'Executed actions' );
        like(
            $response->content,
            qr/bless\( .* 'Catalyst::Request' \)/s,
            'Content is a serialized Catalyst::Request'
        );
    }
}
