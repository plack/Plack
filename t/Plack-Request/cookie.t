use strict;
use warnings;
use Test::More tests => 7;
use HTTP::Request;
use Test::Requires qw(CGI::Simple::Cookie);
use Plack::Test;
use Plack::Request;

my $app = sub {
    my $req = Plack::Request->new(shift);

    is '2', $req->cookie;
    is $req->cookie('undef'), undef;
    is $req->cookie('undef', 'undef'), undef;
    is $req->cookie('Foo')->value, 'Bar';
    is $req->cookie('Bar')->value, 'Baz';
    is_deeply $req->cookies, {Foo => 'Foo=Bar; path=/', Bar => 'Bar=Baz; path=/'};

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $req = HTTP::Request->new(GET => "/");
    $req->header(Cookie => 'Foo=Bar; Bar=Baz');
    $cb->($req);
};

$app = sub {
    my $req = Plack::Request->new(shift);
    is_deeply $req->cookies, {};
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(HTTP::Request->new(GET => "/"));
};

