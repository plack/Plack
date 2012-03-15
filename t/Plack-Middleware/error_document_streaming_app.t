use strict;
use warnings;
use FindBin;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;

my $handler = builder {
    enable "Plack::Middleware::ErrorDocument",
        404 => "$FindBin::Bin/errors/404.html";

    sub {
        my $env = shift;
        my $status = ($env->{PATH_INFO} =~ m!status/(\d+)!)[0] || 200;
        return sub {
            my $r = shift;
            my $w = $r->([ $status, [ 'Content-Type' => 'text/plain' ]]);
            $w->write("Error: $status\n") for 1..3;
            $w->close;
        };
    };
};

test_psgi app => $handler, client => sub {
    my $cb = shift;
    {
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 200;

        $res = $cb->(GET "http://localhost/status/404");
        is $res->code, 404;
        like $res->header('content_type'), qr!text/html!;
        like $res->content, qr/fancy 404/;
    }
};

done_testing;
