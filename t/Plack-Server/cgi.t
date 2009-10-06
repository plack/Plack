use strict;
use warnings;
use Test::More;
use FindBin;
use HTTP::Request::AsCGI;
use URI::Escape;
use Plack;
use Plack::Server::CGI;
use Plack::Test::Suite;

Plack::Test::Suite->runtests(sub {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    my $req = $reqgen->();
    my $cgi = HTTP::Request::AsCGI->new($req);
    $cgi->environment->{PATH_INFO} = uri_unescape $req->uri->path; # fix AsCGI.pm bug
    my $c = $cgi->setup;
    eval { Plack::Server::CGI->new->run($handler) };
    $test->($c->response);
});

done_testing;
