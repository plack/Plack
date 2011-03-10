use strict;
use warnings;
use Test::More;
use Test::Requires { 'Devel::StackTrace::AsHTML' => 0.08 };
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = Plack::Middleware::StackTrace->wrap(sub { die "Foo \x{30c6}" }, no_print_errors => 1);

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    $req->header(Accept => "text/html,*/*");
    my $res = $cb->($req);

    like $res->content, qr/Foo &#12486;/;

    $req = GET "/";
    $res = $cb->($req);
    is $res->code, 500;
    like $res->content, qr/Foo/;
};

done_testing;

