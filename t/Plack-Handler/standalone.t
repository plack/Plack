BEGIN {
  if ( $ENV{NO_NETWORK_TESTING} ) {
    print '1..0 # SKIP Network connections required for this test';
    exit;
  }
}
use strict;
use warnings;
use Test::More;
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('Standalone');
done_testing();

