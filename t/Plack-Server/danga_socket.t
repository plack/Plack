use strict;
use warnings;
use FindBin;
use Test::More;
use Test::Requires qw(Danga::Socket Danga::Socket::Callback HTTP::Parser::XS);

use Plack;
use Plack::Test::Suite;
$Plack::Test::Suite::BaseDir = "$FindBin::Bin/..";

Plack::Test::Suite->run_server_tests('Danga::Socket');
done_testing();
