use strict;
use warnings;
use FindBin;
use Test::More;
use Test::Requires qw(Danga::Socket Danga::Socket::Callback HTTP::Parser::XS);

use Plack;
use Plack::Test;
$Plack::Test::BaseDir = "$FindBin::Bin/..";

Plack::Test->run_server_tests('Danga::Socket');
done_testing();
