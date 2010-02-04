use strict;
use warnings;
use Test::More;
use Test::Requires { 'HTTP::Server::Simple::PSGI' => 0.11 };
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('HTTP::Server::Simple');
done_testing();


