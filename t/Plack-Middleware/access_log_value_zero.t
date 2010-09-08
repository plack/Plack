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
    $req->header("Zero" => "0");

    my $fmt = "%{zero}i %{undef}i";
    $test->($fmt)->($req);
    chomp $log;
    is $log, "0 -";
}

{
    $test->("%D")->(GET "/");
    chomp $log;
    is $log, '-';
}

done_testing;
