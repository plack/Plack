use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Server::Simple);

use FindBin;
use Plack;
use Plack::Test::Suite;
$Plack::Test::Suite::BaseDir = "$FindBin::Bin/..";

Plack::Test::Suite->run_server_tests('ServerSimple');
done_testing();

