use strict;
use warnings;
use Test::More;
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

my $app = sub {
    eval { die "Blah" };

    return [ 500, [ 'Content-Type', 'text/html' ], [ "Fancy Error" ] ];
};

my $default_app = Plack::Middleware::StackTrace->wrap($app, no_print_errors => 1);

test_psgi $default_app, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    is $res->code, 500;
    like $res->content, qr/Fancy Error/;
};

my $force_app = Plack::Middleware::StackTrace->wrap($app, force => 1, no_print_errors => 1);

test_psgi $force_app, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    is $res->code, 500;
    like $res->content, qr/Blah/;
};

done_testing;

