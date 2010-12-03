use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Test;
use Plack::Builder;
use POSIX;

my $log;

my $test = sub {
    my $format = shift;
    return sub {
        my $req = shift;
        my $app = builder {
            enable "Plack::Middleware::AccessLog",
                logger => sub { $log = "@_" }, format => $format;
            sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };
        };
        test_psgi $app, sub { $_[0]->($req) };
    };
};

{
    my $req = GET "http://example.com/";
    $req->header("Host" => "example.com", "X-Forwarded-For" => "192.0.2.1");

    my $fmt = "%{Host}i %{X-Forwarded-For}i %{Content-Type}o %{%m %y}t";
    $test->($fmt)->($req);
    chomp $log;
    my $month_year = POSIX::strftime('%m %y', localtime);
    is $log, "example.com 192.0.2.1 text/plain [$month_year]";
}

{
    $test->("%D")->(GET "/");
    chomp $log;
    is $log, '-';
}

done_testing;
