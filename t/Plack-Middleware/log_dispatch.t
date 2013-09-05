use strict;
use Plack::Test;
use Test::Requires { 'Log::Dispatch' => 2.25, 'Log::Dispatch::Array' => 1.001 };

use Test::More;
use Plack::Middleware::LogDispatch;
use HTTP::Request::Common;
use Log::Dispatch;
use Log::Dispatch::Array;

package Stringify;
use overload q{""} => sub { 'stringified object' };
sub new { bless {}, shift }

package main;

my @logs;

my $logger = Log::Dispatch->new;
$logger->add(Log::Dispatch::Array->new(
    min_level => 'debug',
    array     => \@logs,
));

my $app = sub {
    my $env = shift;
    $env->{'psgix.logger'}->({ level => "debug", message => "This is debug" });
    $env->{'psgix.logger'}->({ level => "info", message => sub { 'code ref' } });
    $env->{'psgix.logger'}->({ level => "notice", message => Stringify->new() });

    return [ 200, [], [] ];
};

$app = Plack::Middleware::LogDispatch->wrap($app, logger => $logger);

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    is @logs, 3;
    is $logs[0]->{level}, 'debug';
    is $logs[0]->{message}, 'This is debug';

    is $logs[1]->{level}, 'info';
    is $logs[1]->{message}, 'code ref';

    is $logs[2]->{level}, 'notice';
    is $logs[2]->{message}, 'stringified object';
};

done_testing;
