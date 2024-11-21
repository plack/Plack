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

plan skip_all => "Skip on Win32" if $^O eq 'MSWin32';

require Plack::Loader::Shotgun;

Plack::Test::Suite->run_server_tests(
    sub {
        my($port, $app) = @_;
        my $loader = Plack::Loader::Shotgun->new;
        $loader->preload_app(sub { $app });
        my $server = $loader->load('Standalone', port => $port, host => '127.0.0.1');
        $loader->run($server);
    },
);

done_testing();
