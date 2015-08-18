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
                char_handlers => {
                    z => sub { shift->{HTTP_X_FORWARDED_FOR}, }
                },
                block_handlers => +{
                    Z => sub {
                        my ($block,$env) = @_;

                        $env->{$block} || '-'
                    }
                },
                logger => sub { $log = "@_" }, format => $format;
            sub { [ 200, [ 'Content-Type' => 'text/plain', 'Content-Length', 2 ], [ 'OK' ] ] };
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

{
    my $req = GET "http://example.com/foo?bar=baz",
        x_forwarded_for => 'herp derp';
    my $fmt = "%m %z";
    $test->($fmt)->($req);
    chomp $log;
    is $log, 'GET herp derp';
}

{
    my $req = GET "http://example.com/foo?bar=baz",
        x_rand_r => 'station';
    my $fmt = "%m %{HTTP_X_RAND_R}Z";
    $test->($fmt)->($req);
    chomp $log;
    is $log, 'GET station';
}

{
    my $req = POST "http://example.com/foo", [ "bar", "baz" ];
    my $fmt = "cti=%{Content-Type}i cli=%{Content-Length}i cto=%{Content-Type}o clo=%{Content-Length}o";
    $test->($fmt)->($req);
    chomp $log;

    my %vals = split /[= ]/, $log;
    is_deeply \%vals, { cti => "application/x-www-form-urlencoded", cli => 7,
                        cto => 'text/plain', clo => 2 };
}

done_testing;
