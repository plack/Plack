use strict;
use warnings;
use Test::More;
use FindBin;
use HTTP::Request::AsCGI;
use Plack;
use Plack::Server::CGI;
use Plack::Test::Suite;
$Plack::Test::Suite::BaseDir = "$FindBin::Bin/..";

Plack::Test::Suite->runtests(sub {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    my $c = HTTP::Request::AsCGI->new($reqgen->())->setup;
    eval { Plack::Server::CGI->new->run($handler) };
    $test->($c->response);
});

done_testing;
