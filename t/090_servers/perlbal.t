use strict;
use warnings;
use Test::More;
use Test::Requires qw(Perlbal);
use Plack;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Plack::Test;
use t::PerlbalUtils;

$Plack::Test::BaseDir = "$FindBin::Bin/..";

Plack::Test->run_server_tests(\&run_perlbal);
done_testing();


