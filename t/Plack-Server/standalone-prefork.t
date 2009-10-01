use strict;
use warnings;
use Test::More;
use Test::Requires {
    'HTTP::Parser::XS' => 0,
    'Parallel::Prefork' => 0.04,
};

use FindBin;
use Plack;
use Plack::Test::Suite;
$Plack::Test::Suite::BaseDir = "$FindBin::Bin/..";

Plack::Test::Suite->run_server_tests('Standalone::Prefork');
done_testing();

