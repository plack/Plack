use strict;
use warnings;
use Test::Requires qw(HTTP::Request::AsCGI);
use Test::More;
use FindBin;
use HTTP::Request::AsCGI;
use URI::Escape;
use Plack;
use Plack::Server::CGI;
use Plack::Test::Suite;

Plack::Test::Suite->runtests(sub {
    my ($name, $test, $handler) = @_;

    note $name;
    my $cb = sub {
        my $req = shift;

        my $cgi = HTTP::Request::AsCGI->new($req);
        $cgi->environment->{PATH_INFO} = uri_unescape $req->uri->path; # fix AsCGI.pm bug
        my $c = $cgi->setup;
        eval { Plack::Server::CGI->new->run($handler) };
        my $res = $c->response;
        $res->request($req);

        $res;
    };

    $test->($cb);
});

done_testing;
