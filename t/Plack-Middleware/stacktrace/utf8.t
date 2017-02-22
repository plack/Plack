use strict;
use warnings;
use Config;
use Test::More;
use Test::Requires { 'Devel::StackTrace::AsHTML' => 0.08 };
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

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

