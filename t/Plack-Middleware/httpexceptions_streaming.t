use strict;
use Plack::Test;
use HTTP::Request::Common;
use Test::More;

package HTTP::Error;
sub new { bless {}, shift }
sub throw {
    my $class = shift;
    die $class->new;
}

package HTTP::Error::InternalServerError;
use base qw(HTTP::Error);
sub code { 500 }

package HTTP::Error::Forbidden;
use base qw(HTTP::Error);
sub code { 403 }
sub as_string { "blah blah blah" }

package main;

my $app = sub {
    my $env = shift;
    if ($env->{PATH_INFO} eq '/secret') {
        return sub { HTTP::Error::Forbidden->throw };
    } elsif ($env->{PATH_INFO} eq '/ok') {
        return sub {
            my $res = shift;
            my $w = $res->([ 200, [ 'Content-Type', 'text/plain' ] ]);
            $w->write("Hello");
            $w->close;
        };
    }

    return sub { HTTP::Error::InternalServerError->throw };
};

use Plack::Middleware::HTTPExceptions;
$app = Plack::Middleware::HTTPExceptions->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 500;
    is $res->content, 'Internal Server Error';

    $res = $cb->(GET "/secret");
    is $res->code, 403;
    is $res->content, 'blah blah blah';

    $res = $cb->(GET "/ok");
    is $res->code, 200;
    is $res->content, 'Hello';
};

done_testing;
