use strict;
use warnings;
use Test::More;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

my $handler = builder {
    enable "Plack::Middleware::MethodOverride";
    sub {
        my $env = shift;
        [ 200, ['Content-Type' => 'text/plain' ], [ $env->{REQUEST_METHOD} ] ];
    };
};

test_psgi app => $handler, client => sub {
    my $cb  = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->content, 'GET';

    $res = $cb->(POST "http://localhost/", 'X-HTTP-Method-Override' => 'DELETE');
    is $res->content, 'DELETE';
};

done_testing;
