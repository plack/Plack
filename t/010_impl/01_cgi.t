use strict;
use warnings;
use Test::More;
use HTTP::Request::AsCGI;
use_ok('Plack');
use_ok('Plack::Impl::CGI');
use Plack::Test;

Plack::Test->runtests(sub {
    my ($name, $reqgen, $handler, $test) = @_;
    note $name;
    my $c = HTTP::Request::AsCGI->new($reqgen->())->setup;
    Plack::Impl::CGI->run($handler);
    $test->($c->response);
});

done_testing;
