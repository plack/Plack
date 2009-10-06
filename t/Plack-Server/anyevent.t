use strict;
use warnings;
use FindBin;
use Test::More;
use Test::Requires qw(AnyEvent HTTP::Parser::XS);

use Plack;
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('AnyEvent');
done_testing();
