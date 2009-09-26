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

test_tcp(
    client => sub {
        my $port = shift;
        for my $i (0..$#Plack::Test::TEST) {
            my $test = $Plack::Test::TEST[$i];
            note $test->[0];
            my $ua  = LWP::UserAgent->new;
            my $req = $test->[1]->($port);
            $req->header('X-Plack-Test' => $i);
            my $res = $ua->request($req);
            local $Test::Builder::Level = $Test::Builder::Level + 3;
            $test->[3]->($res, $port);
        }
    },
    server => sub {
        my $port = shift;
        run_perlbal($port);
    },
);

done_testing();


