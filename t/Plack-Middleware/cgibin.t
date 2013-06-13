use strict;
use Test::More;
plan skip_all => "release test only" unless $ENV{RELEASE_TESTING};

use Test::Requires { 'CGI::Emulate::PSGI' => 0.10, 'CGI::Compile' => 0.03 };
use Plack::Test;
use HTTP::Request::Common;
use Plack::App::CGIBin;

my $app = Plack::App::CGIBin->new(root => "t/Plack-Middleware/cgi-bin")->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/hello.cgi?name=foo");
    is $res->code, 200;
    is $res->content, "Hello foo counter=1";

    $res = $cb->(GET "http://localhost/hello.cgi?name=bar");
    is $res->code, 200;
    is $res->content, "Hello bar counter=2";

    $res = $cb->(GET "http://localhost/hello2.cgi?name=foo");
    is $res->code, 200;
    is $res->content, "Hello foo counter=1";

    $res = $cb->(GET "http://localhost/hello3.cgi");
    my $env = eval $res->content;
    is $env->{SCRIPT_NAME}, '/hello3.cgi';
    is $env->{REQUEST_URI}, '/hello3.cgi';

    $res = $cb->(GET "http://localhost/hello3.cgi/foo%20bar/baz");
    is $res->code, 200;
    $env = eval $res->content || {};
    is $env->{SCRIPT_NAME}, '/hello3.cgi';
    is $env->{PATH_INFO}, '/foo bar/baz';
    is $env->{REQUEST_URI}, '/hello3.cgi/foo%20bar/baz';

    $res = $cb->(GET "http://localhost/hello4.cgi");
    is $res->code, 404;

    $res = $cb->(GET "http://localhost/utf8.cgi");
    is $res->code, 200;
    is length $res->content, 4;
    is $res->content, "\xe1\x83\xb7\n";
};

$app = Plack::App::CGIBin->new(
    root => "t/Plack-Middleware/cgi-bin",
    exec_cb => sub { 1 } )->to_app;

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(GET "http://localhost/cgi_dir.cgi");
    is $res->code, 200;
    is $res->content, "MATCH";
};

done_testing;
