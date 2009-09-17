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

use Data::Dumper;

my $i = 0;
Plack::Test->runtests(\&run_one);
done_testing();

sub run_one {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    test_tcp(
        client => sub {
            my $port = shift;
            my $ua = LWP::UserAgent->new();
            my $res = $ua->request($reqgen->($port));
            $test->($res, $port);
        },
        server => sub {
            my $port = shift;
            run_perlbal($port, $i);
        },
    );

    $i++;
}


