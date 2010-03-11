use strict;
use warnings;
use Test::More;
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

my $app = Plack::Middleware::StackTrace->wrap(sub { die "orz" });

test_psgi $app, sub {
    my $cb = shift;

    my $req = GET "/";
    $req->header(Accept => "text/html,*/*");
    my $res = $cb->($req);

    ok $res->is_error;
    is_deeply [ $res->content_type ], [ 'text/html', 'charset=utf-8' ];
    like $res->content, qr/orz/;
};

done_testing;

