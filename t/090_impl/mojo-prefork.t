use strict;
use warnings;
use Test::More;
use Test::Requires qw(Mojo::Server::Daemon::Prefork);

use Plack;
use Plack::Test;

Plack::Test->run_server_tests('Mojo::Prefork');
done_testing();
