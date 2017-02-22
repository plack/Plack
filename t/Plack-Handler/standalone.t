use strict;
use warnings;
use Config;
use Test::More;
use Plack::Test::Suite;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

Plack::Test::Suite->run_server_tests('Standalone');
done_testing();

