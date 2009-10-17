use strict;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::Chunked;
$Plack::Test::Impl = "Server";

my $app = sub { [ 200, [], [ 'Hello World' ] ] };

test_psgi app => Plack::Middleware::Chunked->wrap($app), client => sub {
    my $cb = shift;
    my $res = $cb->(GET "http://localhost/");

    is $res->content, 'Hello World';
    is $res->decoded_content, 'Hello World';
    is $res->header('client-transfer-encoding'), 'chunked';
};

done_testing;
