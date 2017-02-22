use strict;
use Config;
use Test::More;
use Plack::App::URLMap;
use Plack::Test;
use HTTP::Request::Common;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $make_app = sub {
    my $name = shift;
    sub {
        my $env = shift;
        my $body = join "|", $name, $env->{SCRIPT_NAME}, $env->{PATH_INFO};
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ $body ] ];
    };
};

my $app1 = $make_app->("app1");
my $app2 = $make_app->("app2");

my $app = Plack::App::URLMap->new;
$app->map("http://127.0.0.1/" => $app1);
$app->map("/" => $app2);

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res;
    $res = $cb->(GET "http://127.0.0.1/");
    is $res->content, 'app1||/';
};

done_testing;
