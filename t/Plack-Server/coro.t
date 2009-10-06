use strict;
use warnings;
use Test::More;
use Test::Requires qw(Net::Server::Coro);

use FindBin;
use Plack;
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('Coro');
done_testing();

