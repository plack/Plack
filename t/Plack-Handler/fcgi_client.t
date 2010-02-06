use strict;
use warnings;
use Test::More;
use Test::Requires { FCGI => 0, 'FCGI::Client' => 0.04 };
use Plack;
use Plack::Handler::FCGI;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Plack::Test::Suite;
use t::FCGIUtils;

plan skip_all => "Set TEST_FCGI_CLIENT to test this"
    unless $ENV{TEST_FCGI_CLIENT};

my $http_port;
my $fcgi_port;

test_fcgi_standalone(
   sub {
       ($http_port, $fcgi_port) = @_;
       Plack::Test::Suite->run_server_tests(\&run_server, $fcgi_port, $http_port);
       done_testing();
    }
);

sub run_server {
    my($port, $app) = @_;

    $| = 0; # Test::Builder autoflushes this. reset!

    my $server = Plack::Handler::FCGI->new(
        host        => '127.0.0.1',
        port        => $port,
        manager     => '',
        keep_stderr => 1,
    );
    $server->run($app);
}


