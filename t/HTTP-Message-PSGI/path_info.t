use strict;
use Test::More;
use HTTP::Message::PSGI qw(req_to_psgi);
use HTTP::Request::Common;

my $env = req_to_psgi GET "http://localhost/foo";
is $env->{PATH_INFO}, "/foo";

$env = req_to_psgi GET "http://localhost/";
is $env->{SCRIPT_NAME}, "";
is $env->{PATH_INFO}, "/";

$env = req_to_psgi GET "http://localhost/0";
is $env->{SCRIPT_NAME}, "";
is $env->{PATH_INFO}, "/0";

$env = req_to_psgi GET "http://localhost";
is $env->{SCRIPT_NAME}, "";
is $env->{PATH_INFO}, "/";
is $env->{REQUEST_URI}, "/";


done_testing;
