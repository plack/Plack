use strict;
use warnings;
use Test::More;
use Test::Requires { 'Net::FastCGI' => 0.08, 'FCGI::Client' => 0.04 };
use Plack::Handler::FCGI::PP;
use Test::TCP;
use Plack::Test::Suite;
use t::FCGIUtils;

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

    my $server = Plack::Handler::FCGI::PP->new(
        host        => '127.0.0.1',
        port        => $port,
    );
    $server->run($app);
}


