use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Parser::XS);

use FindBin;
use Plack;
use Plack::Test;
$Plack::Test::BaseDir = "$FindBin::Bin/..";

Plack::Test->run_server_tests('Standalone');
done_testing();

