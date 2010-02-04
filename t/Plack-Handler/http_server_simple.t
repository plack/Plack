use strict;
use warnings;
use Test::More;
use Test::Requires qw(HTTP::Server::Simple::PSGI);
use Plack::Test::Suite;

Plack::Test::Suite->run_server_tests('HTTP::Server::Simple');
done_testing();


