use strict;
use Test::More;
plan skip_all => "Hangs on Windows" if $^O eq 'MSWin32'; 
use Test::Requires { 'CGI::Emulate::PSGI' => 0.06, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::WrapCGI;
use IO::File;
use File::Temp;

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

$app = Plack::App::WrapCGI->new(
  script => "t/Plack-Middleware/cgi-bin/cgi_dir.cgi",
  execute => 1)->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/?");
    is $res->code, 200;
    is $res->content, "MATCH";
};

done_testing;
