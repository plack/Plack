use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $log;
my $handler = builder {
    add "Plack::Middleware::ErrorDocument",
        500 => "$FindBin::Bin/errors/500.html";
    add "Plack::Middleware::ErrorDocument",
        404 => "/errors/404.html", subrequest => 1;
    add "Plack::Middleware::Static",
        path => qr{^/errors}, root => $FindBin::Bin;

    sub {
        my $env = shift;
        my $status = ($env->{PATH_INFO} =~ m!status/(\d+)!)[0] || 200;
        [ $status, [ 'Content-Type' => 'text/plain' ], [ "Error: $status" ] ];
    };
};

test_psgi app => $handler, client => sub {
    my $cb = shift;
    {
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 200;

        $res = $cb->(GET "http://localhost/status/500");
        is $res->code, 500;
        like $res->content, qr/fancy 500/;

        $res = $cb->(GET "http://localhost/status/404");
        is $res->code, 404;
        like $res->content, qr/fancy 404/;
    }
};

done_testing;
