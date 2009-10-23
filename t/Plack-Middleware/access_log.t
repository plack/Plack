use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use POSIX;

my $log;
my $handler = builder {
    enable "Plack::Middleware::AccessLog",
        logger => sub { $log .= "@_" }, format => "%{Host}i %{Content-Type}o %{%m %y}t";
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
    my $req = GET "http://example.com/";
    $req->header("Host" => "example.com");
    $test_req->($req);
    chomp $log;
    my $month_year = POSIX::strftime('%m %y', localtime);
    is $log, "example.com text/plain [$month_year]";
}

done_testing;
