#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 28;
use Catalyst::Test 'TestApp';

local $^W = 0;

my $uri_base = 'http://localhost/priorities';
my @tests = (

    #   Simple
    'Regex vs. Local',      { path => '/re_vs_loc',      expect => 'local' },
    'Regex vs. LocalRegex', { path => '/re_vs_locre',    expect => 'regex' },
    'Regex vs. Path',       { path => '/re_vs_path',     expect => 'path' },
    'Local vs. LocalRegex', { path => '/loc_vs_locre',   expect => 'local' },
    'Local vs. Path 1',     { path => '/loc_vs_path1',   expect => 'local' },
    'Local vs. Path 2',     { path => '/loc_vs_path2',   expect => 'path' },
    'Path  vs. LocalRegex', { path => '/path_vs_locre',  expect => 'path' },

    #   index
    'index vs. Regex',      { path => '/re_vs_index',    expect => 'index' },
    'index vs. Local',      { path => '/loc_vs_index',   expect => 'index' },
    'index vs. LocalRegex', { path => '/locre_vs_index', expect => 'index' },
    'index vs. Path',       { path => '/path_vs_index',  expect => 'index' },

    'multimethod zero',     { path => '/multimethod',    expect => 'zero' },
    'multimethod one',      { path => '/multimethod/1',  expect => 'one 1' },
    'multimethod two',      { path => '/multimethod/1/2',
                                                         expect => 'two 1 2' },
);

while ( @tests ) {

    my $name = shift @tests;
    my $data = shift @tests;

    #   Run tests for path with trailing slash and without
  SKIP: for my $req_uri 
    ( 
        join( '' => $uri_base, $data->{ path } ),      # Without trailing path
        join( '' => $uri_base, $data->{ path }, '/' ), # With trailing path
    ) {
        my $end_slash = ( $req_uri =~ qr(/$) ? 1 : 0 );

        #   use slash_expect argument if URI ends with slash 
        #   and the slash_expect argument is defined
        my $expect = $data->{ expect } || '';
        if ( $end_slash and exists $data->{ slash_expect } ) {
            $expect = $data->{ slash_expect };
        }

        #   Call the URI on the TestApp
        my $response = request( $req_uri );

        #   Leave expect out to see the result
        unless ( $expect ) {
            skip 'Nothing expected, winner is ' . $response->content, 1;
        }

        #   Show error if response was no success
        if ( not $response->is_success ) {
            diag 'Error: ' . $response->headers->{ 'x-catalyst-error' };
        }

        #   Test if content matches expectations.
        #   TODO This might flood the screen with the catalyst please-come-later
        #        page. So I don't know it is a good idea.
        is( $response->content, $expect,
            "$name: @{[ $data->{ expect } ]} wins"
            . ( $end_slash ? ' (trailing slash)' : '' )
        );
    }
}

