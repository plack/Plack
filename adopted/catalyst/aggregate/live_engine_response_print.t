#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 9;
use Catalyst::Test 'TestApp';

my $expected = {
   one => "foo",
   two => "foobar",
   three => "foo,bar,baz",
};

for my $action ( sort keys %{$expected} ) {
    ok( my $response = request('http://localhost/engine/response/print/' . $action ),
        'Request' );
    ok( $response->is_success, "Response $action successful 2xx" );
    
    is( $response->content, $expected->{$action}, "Content $action OK" );
}
