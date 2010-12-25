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
    local $ENV{PLACK_TEST_HANDLER} = 'CGI';
    local $ENV{PLACK_TEST_SCRIPT_NAME} = '/plack_test.cgi';

    note $name;
    my $cb = sub {
        my $req = shift;

        my $cgi = HTTP::Request::AsCGI->new($req);
        my $c = $cgi->setup;

        # Fix CGI container parameters
        $ENV{SCRIPT_NAME} = '/plack_test.cgi';
        $ENV{REQUEST_URI} = "/plack_test.cgi$ENV{REQUEST_URI}";

        # Apache's CGI implementation does not pass "Authorization" header by untrusted ENV.
        # We bow down to it under this test.
        delete $ENV{HTTP_AUTHORIZATION};

        eval { Plack::Handler::CGI->new->run($handler) };
        my $res = $c->response;
        $res->request($req);

        $res;
    };

    $test->($cb);
});

done_testing;
