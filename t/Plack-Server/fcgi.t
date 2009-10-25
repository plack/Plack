use strict;
use warnings;
use Test::More;
use Test::Requires qw(FCGI FCGI::ProcManager);
use Plack;
use Plack::Server::FCGI;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Plack::Test::Suite;
use t::FCGIUtils;

my $lighty_port;
my $fcgi_port;

test_lighty_external(
   sub {
       ($lighty_port, $fcgi_port) = @_;
       Plack::Test::Suite->run_server_tests(\&run_one, $fcgi_port, $lighty_port);
       done_testing();
    }
);

sub run_one {
    my($port, $app) = @_;

    my $server = Plack::Server::FCGI->new(
        host        => '127.0.0.1',
        port        => $port,
        manager     => '',
        keep_stderr => 1,
    );
    $server->run($app);
}


