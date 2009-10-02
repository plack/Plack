use strict;
use warnings;
use Test::More;
use FindBin;
use HTTP::Message::PSGI;
use Plack;
use Plack::Test::Suite;
$Plack::Test::Suite::BaseDir = "$FindBin::Bin/..";

Plack::Test::Suite->runtests(sub {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    my $env = req_to_psgi($reqgen->());
    eval {
        my $res = res_from_psgi($handler->($env));
        $test->($res);
    };
    fail $@ if $@ && $@ !~ /an exception from app/;
});

done_testing;
