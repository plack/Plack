use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Server::Simple);

use Plack;
use Plack::Test;

Plack::Test->run_server_tests('ServerSimple');
done_testing();

