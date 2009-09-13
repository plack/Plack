use strict;
use warnings;
use Test::More;
use Test::Requires {
    Mojo => 0.991244, ## for Mojo::Server::Daemon->address
    'Mojo::Server::Daemon::Prefork' => 0,
};

use Plack;
use Plack::Test;

Plack::Test->run_server_tests('Mojo::Prefork');
done_testing();
