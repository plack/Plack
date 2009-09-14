use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Parser::XS);

use Plack;
use Plack::Test;

Plack::Test->run_server_tests('Standalone');
done_testing();

