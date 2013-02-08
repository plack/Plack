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

    my $fmt = "%P %{Host}i %p %{X-Forwarded-For}i %{Content-Type}o %{%m %y}t %v";
    $test->($fmt)->($req);
    chomp $log;
    my $month_year = POSIX::strftime('%m %y', localtime);
    is $log, "$$ example.com 80 192.0.2.1 text/plain [$month_year] example.com";
}

{
    $test->("%D")->(GET "/");
    chomp $log;
    is $log, '-';
}

{
    my $req = GET "http://example.com/";
    my $fmt = "%r == %m %U%q %H";
    $test->($fmt)->($req);
    chomp $log;
    my ($r, $rs) = split / == /, $log;
    is $r, $rs;
}

{
    my $req = GET "http://example.com/foo?bar=baz";
    my $fmt = "%r == %m %U%q %H";
    $test->($fmt)->($req);
    chomp $log;
    my ($r, $rs) = split / == /, $log;
    is $r, $rs;
}

done_testing;
