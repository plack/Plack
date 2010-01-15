use strict;
use Test::More;
use Test::Requires { 'CGI::Emulate::PSGI' => 0, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::WrapCGI;

my $app = Plack::App::WrapCGI->new(script => "t/Plack-Middleware/cgi-bin/hello.cgi")->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/?name=foo");
    is $res->code, 200;
    is $res->content, "Hello foo counter=1";

    $res = $cb->(GET "http://localhost/?name=bar");
    is $res->code, 200;
    is $res->content, "Hello bar counter=2";
};

done_testing;
