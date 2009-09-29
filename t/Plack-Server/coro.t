use strict;
use warnings;
use Test::More;
use Test::Requires qw(Net::Server::Coro);

use FindBin;
use Plack;
use Plack::Test;
$Plack::Test::BaseDir = "$FindBin::Bin/..";

Plack::Test->run_server_tests('Coro');
done_testing();

