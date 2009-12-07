use strict;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::PSGIBin;

my $app = Plack::App::PSGIBin->new(root => "eg/dot-psgi")->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/Hello.psgi?name=foo");
    is $res->code, 200;
    is $res->content, "Hello World";
};

done_testing;
