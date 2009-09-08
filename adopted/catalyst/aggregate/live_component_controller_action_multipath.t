#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

my $content = q/foo
bar
baz
/;

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More tests => 16*$iters;
use Catalyst::Test 'TestApp';

if ( $ENV{CAT_BENCHMARK} ) {
    require Benchmark;
    Benchmark::timethis( $iters, \&run_tests );
}
else {
    for ( 1 .. $iters ) {
        run_tests($content);
    }
}

sub run_tests {
    my ($content) = @_;

    # Local
    {
        ok(
            my $response =
              request('http://localhost/action/multipath/multipath'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->content, $content, 'Content is a stream' );
    }

    # Global
    {
        ok( my $response = request('http://localhost/multipath'), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->content, $content, 'Content is a stream' );
    }

    # Path('/multipath1')
    {
        ok( my $response = request('http://localhost/multipath1'), 'Request' );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->content, $content, 'Content is a stream' );
    }

    # Path('multipath2')
    {
        ok(
            my $response =
              request('http://localhost/action/multipath/multipath2'),
            'Request'
        );
        ok( $response->is_success, 'Response Successful 2xx' );
        is( $response->content_type, 'text/plain', 'Response Content-Type' );
        is( $response->content, $content, 'Content is a stream' );
    }
}
