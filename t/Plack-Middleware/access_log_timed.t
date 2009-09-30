use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware qw(AccessLog::Timed);
use Plack::Builder;

my $log;
my $handler = builder {
    enable Plack::Middleware::AccessLog::Timed
        logger => sub { $log .= "@_" };
    sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
};

my $test_req = sub {
    my $req = shift;
    test_psgi app => $handler,
        client => sub {
        my $cb = shift;
        $cb->($req);
    };
};

{
    $test_req->(GET "http://localhost/");
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "GET / HTTP/1\.1" 200 2@;
}

{
    $log = "";
    $test_req->(POST "http://localhost/foo", { foo => "bar" });
    like $log, qr@^127\.0\.0\.1 - - \[.*?\] "POST /foo HTTP/1\.1" 200 2@;
}



done_testing;
