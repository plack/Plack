use strict;
use warnings;
use Test::More;
use FindBin;
use HTTP::Message::PSGI;
use Plack;
use Plack::Test::Suite;
use Plack::Util;

Plack::Test::Suite->runtests(sub {
    my ($name, $test, $handler) = @_;
    note $name;
    my $cb = sub {
        my $req = shift;
        my $env = req_to_psgi($req);
        my $res = res_from_psgi(Plack::Util::run_app $handler, $env);
        $res->request($req);
        return $res;
    };
    $test->($cb);
});

done_testing;
