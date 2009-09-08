use strict;
use warnings;
use Test::More;
use Test::Requires qw(AnyEvent);

use Plack;
use Plack::Test;

Plack::Test->run_server_tests('ServerSimple');
done_testing();
