use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI;
use Plack::Middleware::AccessLog::Timed;
use HTTP::Request;
use HTTP::Response;

# Plack::Middleware::AccessLog::Timed is used here as it always uses
# a coderef in response_cb to wrap the response body.
my $app = Plack::Middleware::AccessLog::Timed->wrap(
    sub { return [ 200, [], []] },
    logger => sub {},
);

my $env = req_to_psgi(HTTP::Request->new(POST => "http://localhost/post", [ ], 'hello'));

my $response = HTTP::Response->from_psgi($app->($env));

is($response->content, '', 'undef response body converted to empty string');

done_testing;

