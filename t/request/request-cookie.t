use strict;
use warnings;
use Test::More tests => 7;
use t::Utils;
use HTTP::Request;
use CGI::Simple::Cookie;

# exist Cookie header.
do {
    # do test
    do {
        my $req = req(
            env => {
                HTTP_COOKIE    => 'Foo=Bar; Bar=Baz',
                REQUEST_METHOD => 'GET',
                SCRIPT_NAME    => '/',
            },
        );
        is '2', $req->cookie;
        is $req->cookie('undef'), undef;
        is $req->cookie('undef', 'undef'), undef;
        is $req->cookie('Foo')->value, 'Bar';
        is $req->cookie('Bar')->value, 'Baz';
        is_deeply $req->cookies, {Foo => 'Foo=Bar; path=/', Bar => 'Bar=Baz; path=/'};
    };
};

# no Cookie header
do {
    # do test
    do {
        my $req = req(
            env => {
                REQUEST_METHOD => 'GET',
                SCRIPT_NAME    => '/',
            },
        );
        is_deeply $req->cookies, {};
    };
};

