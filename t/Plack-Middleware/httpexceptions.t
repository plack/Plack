use strict;
use Plack::Test;
use HTTP::Request::Common;
use Test::More;
BEGIN { $ENV{'PLACK_ENV'} = 'deployment' }

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

package MyMiddleware;
use base 'Plack::Middleware';
sub call {
  my ( $self, $env ) = @_;
  die 'Unknown error, but on test purpose'
    if $env->{'PATH_INFO'} eq '/unknow_error';
  return $self->app->($env);
}

package main;

my $app = sub {
    my $env = shift;
    if ($env->{PATH_INFO} eq '/secret') {
        HTTP::Error::Forbidden->throw;
    }
    if ($env->{PATH_INFO} eq '/redirect') {
        HTTP::Error::Redirect->throw;
    }
    HTTP::Error::InternalServerError->throw;
};

use Plack::Middleware::HTTPExceptions;
$app = MyMiddleware->wrap($app);
$app = Plack::Middleware::HTTPExceptions->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET '/unknow_error');
    is $res->code, 500;
    is $res->content, 'Internal Server Error';
    $res = $cb->(GET "/");
    is $res->code, 500;
    is $res->content, 'Internal Server Error';

    $res = $cb->(GET "/secret");
    is $res->code, 403;
    is $res->content, 'blah blah blah';

    $res = $cb->(GET '/redirect');
    is $res->code, 302;
    is $res->header('Location'), 'http://somewhere/else';
};

done_testing;
