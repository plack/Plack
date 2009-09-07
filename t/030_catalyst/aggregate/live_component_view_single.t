#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More;
use Catalyst::Test 'TestAppOneView';

plan 'skip_all' if ( $ENV{CATALYST_SERVER} );

plan tests => 3*$iters;

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
        is(get('/view_by_name?view=Dummy'), 'AClass',
            '$c->view("name") returns blessed instance');
        is(get('/view_by_regex?view=Dummy'), 'AClass',
            '$c->view(qr/name/) returns blessed instance');
        is(get('/view_no_args'), 'AClass',
            '$c->view() returns blessed instance');
    }
}
