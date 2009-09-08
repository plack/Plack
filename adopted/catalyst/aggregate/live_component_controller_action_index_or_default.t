#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1; }

use Test::More;
use Catalyst::Test 'TestAppIndexDefault';

plan 'skip_all' if ( $ENV{CATALYST_SERVER} );

plan tests => 6*$iters;

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
    is(get('/indexchained'), 'index_chained', ':Chained overrides index');
    is(get('/indexprivate'), 'index_private', 'index : Private still works');

# test :Path overriding default
    is(get('/one_arg'), 'path_one_arg', ':Path overrides default');
    is(get('/one_arg/foo/bar'), 'default', 'default still works');

# now the same thing with a namespace, and a trailing / on the :Path
    is(get('/default/one_arg'), 'default_path_one_arg',
        ':Path overrides default');
    is(get('/default/one_arg/foo/bar'), 'default_default',
        'default still works');
}
