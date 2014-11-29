use Config;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

plan skip_all => "fork not supported on this platform"
  unless $Config::Config{d_fork} || $Config::Config{d_pseudofork} ||
    (($^O eq 'MSWin32' || $^O eq 'NetWare') and
     $Config::Config{useithreads} and
     $Config::Config{ccflags} =~ /-DPERL_IMPLICIT_SYS/);

$Plack::Test::Impl = 'Server';
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    my $req = Plack::Request->new(shift);
    return [200, [], [ $req->uri ]];
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(GET "http://localhost/foo");
    ok $res->content !~ /:\d+:\d+/;
};

done_testing;


