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

package HTTP::Error::Redirect;
use base qw(HTTP::Error);
sub code { 302 }
sub location { "http://somewhere/else" }

package main;

my $psgi_errors;

my $app = sub {
    my $env = shift;

    $env->{'psgi.errors'} = do { open my $io, ">>", \$psgi_errors; $io };

    if ($env->{PATH_INFO} eq '/secret') {
        HTTP::Error::Forbidden->throw;
    }
    if ($env->{PATH_INFO} eq '/redirect') {
        HTTP::Error::Redirect->throw;
    }

    if ($env->{PATH_INFO} eq '/uncaught') {
        die 'ugly stack trace here';
    }

    HTTP::Error::InternalServerError->throw;
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

    $res = $cb->(GET '/redirect');
    is $res->code, 302;
    is $res->header('Location'), 'http://somewhere/else';

    $res = $cb->(GET '/uncaught');
    is $res->code, 500;
    like $psgi_errors, qr/ugly stack trace here/;
};

done_testing;
