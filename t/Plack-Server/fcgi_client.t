use strict;
use warnings;
use Test::More;
use Test::Requires { FCGI => 0, 'FCGI::Client' => 0.03 };
use Plack;
use Plack::Server::FCGI;
use Test::TCP;
use LWP::UserAgent;
use FindBin;
use Plack::Test::Suite;
use t::FCGIUtils;


use Data::Dumper;

my $http_port;
my $fcgi_port;

test_fcgi_standalone(
   sub {
       ($http_port, $fcgi_port) = @_;
       Plack::Test::Suite->run_server_tests(\&run_one, $fcgi_port, $http_port);
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


