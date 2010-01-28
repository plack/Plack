use strict;
use Plack::Test;
use Test::More;
use Plack::Response;
use HTTP::Request::Common;

my $app = sub {
    my $res = Plack::Response->new(200);

    $res->cookies->{foo} = { value => "bar", domain => '.example.com', path => '/cgi-bin' };
    $res->cookies->{bar} = { value => "xxx yyy", expires => time + 3600 };
    $res->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    my @v = sort $res->header('Set-Cookie');
    like $v[0], qr/bar=xxx%20yyy; expires=\w+, \d+-\w+-\d+ \d\d:\d\d:\d\d GMT/;
    is $v[1], "foo=bar; domain=.example.com; path=/cgi-bin";
};

done_testing;
