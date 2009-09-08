#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use URI::Escape;

our @paths;
our $iters;

BEGIN { $iters = $ENV{CAT_BENCH_ITERS} || 1;

    # add special paths to test here
    @paths = (
        # all reserved in uri's
        qw~ : / ? [ ] @ ! $ & ' ( ) * + ; = ~, ',' , '#',

        # unreserved
        'a'..'z','A'..'Z',0..9,qw( - . _ ~ ),
        " ",

        # just to test %2F/%
        [ qw~ / / ~ ],

        # testing %25/%25
        [ qw~ % % ~ ],
    );
}

use Test::More tests => 6*@paths * $iters;
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
    run_test_for($_) for @paths;
}

sub run_test_for {
    my $test = shift;

    my $path;
    if (ref $test) {
        $path = join "/", map uri_escape($_), @$test;
        $test = join '', @$test;
    } else {
        $path = uri_escape($test);
    }
    
    SKIP:
    {   
        # Skip %2F, ., [, (, and ) tests on real webservers
        # Both Apache and lighttpd don't seem to like these
        if ( $ENV{CATALYST_SERVER} && $path =~ /(?:%2F|\.|%5B|\(|\))/ ) {
            skip "Skipping $path tests on remote server", 6;
        }

        my $response;

        ok( $response = request("http://localhost/args/args/$path"), "Requested args for path $path");

        is( $response->content, $test, "$test as args" );

        undef $response;

        ok( $response = request("http://localhost/args/params/$path"), "Requested params for path $path");

        is( $response->content, $test, "$test as params" );

        undef $response;

        if( $test =~ m{/} ) {
            $test =~ s{/}{}g;
            $path = uri_escape( $test ); 
        }

        ok( $response = request("http://localhost/chained/multi_cap/$path/baz"), "Requested capture for path $path");

        is( $response->content, join( ', ', split( //, $test ) ) ."; ", "$test as capture" );
    }
}

