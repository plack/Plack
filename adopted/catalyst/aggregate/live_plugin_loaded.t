#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 5;
use Catalyst::Test 'TestApp';

my @expected = qw[
  Catalyst::Plugin::Test::Errors
  Catalyst::Plugin::Test::Headers
  Catalyst::Plugin::Test::Inline
  Catalyst::Plugin::Test::MangleDollarUnderScore
  Catalyst::Plugin::Test::Plugin
  TestApp::Plugin::AddDispatchTypes
  TestApp::Plugin::FullyQualified
];

my $expected = join( ", ", @expected );

ok( my $response = request('http://localhost/dump/request'), 'Request' );
ok( $response->is_success, 'Response Successful 2xx' );
is( $response->content_type, 'text/plain', 'Response Content-Type' );
like( $response->content, qr/'Catalyst::Request'/,
    'Content is a serialized Catalyst::Request' );
is( $response->header('X-Catalyst-Plugins'), $expected, 'Loaded plugins' );
