use strict;
use warnings;
use Test::More;
use Test::Requires qw(Mojo::Server::Daemon);

use Plack;
use Plack::Test;

Plack::Test->run_server_tests('Mojo');
done_testing();
