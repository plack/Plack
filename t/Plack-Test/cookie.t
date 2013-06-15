use strict;
use Plack::Test;
use HTTP::Request::Common;
use Test::More;
use Test::Requires qw(HTTP::Cookies);

my $app = sub {
    return [ 200, [ 'Content-Type' => 'text/html', 'Set-Cookie' => "ID=123; path=/" ], [ "Hi" ] ];
};

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");

    my $cookie_jar = HTTP::Cookies->new;
    $cookie_jar->extract_cookies($res);

    my @cookies;
    $cookie_jar->scan( sub { @cookies = @_ });

    ok @cookies;
    is $cookies[1], 'ID';
};

done_testing;
