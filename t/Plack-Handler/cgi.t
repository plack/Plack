use strict;
use warnings;
use Test::Requires {
    'HTTP::Request::AsCGI' => 1.2,
};
use Test::More;
use FindBin;
use HTTP::Request::AsCGI;
use URI::Escape;
use Plack;
use Plack::Handler::CGI;
use Plack::Test::Suite;

Plack::Test::Suite->runtests(sub {
    my ($name, $test, $handler) = @_;

    note $name;
    my $cb = sub {
        my $req = shift;

        my $cgi = HTTP::Request::AsCGI->new($req);
        my $c = $cgi->setup;
        $ENV{SCRIPT_NAME} = '/plack_test.cgi';
        eval { Plack::Handler::CGI->new->run($handler) };
        my $res = $c->response;
        $res->request($req);

        $res;
    };

    $test->($cb);
});

done_testing;
