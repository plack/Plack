use strict;
use warnings;
use Test::More;
use Test::Requires {
    'HTTP::Parser::XS' => 0,
    'Parallel::Prefork' => 0.04,
};

use FindBin;
use Plack;
use Plack::Test;
$Plack::Test::BaseDir = "$FindBin::Bin/..";

Plack::Test->run_server_tests('Prefork');
done_testing();

