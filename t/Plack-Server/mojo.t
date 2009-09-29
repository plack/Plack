use strict;
use warnings;
use Test::More;
use Test::Requires {
    Mojo => 0.991244, ## for Mojo::Server::Daemon->address
    'Mojo::Server::Daemon::Prefork' => 0,
};

use FindBin;
use Plack;
use Plack::Test::Suite;
$Plack::Test::Suite::BaseDir = "$FindBin::Bin/..";

Plack::Test::Suite->run_server_tests('Mojo');
done_testing();
