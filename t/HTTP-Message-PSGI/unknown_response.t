use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI;
use HTTP::Request;
use HTTP::Response;

my $res;
my $app = sub { $res };
my $env = req_to_psgi(HTTP::Request->new(GET => "http://localhost/"));

eval { HTTP::Response->from_psgi($app->($env)) };
like($@, qr/Bad response: undef/, 'converting undef PSGI response results in error');

$res = 5;

eval { HTTP::Response->from_psgi($app->($env)) };
like($@, qr/Bad response: 5/, 'converting invalid PSGI response results in error');

done_testing;
