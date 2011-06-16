use strict;
use warnings;
use Test::More;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

plan tests => 5;

my $app = sub {
    [200, ['Content-Type', 'text/plain'], ['ok']]
};

my $mw = MyMiddleware->new;

ok my $builder = Plack::Builder->new();
$builder->add_middleware('Runtime');
$app = $builder->mount('/app/foo/bar' => $app);
$builder->add_middleware( $mw );
$builder->add_middleware('XFramework', framework => 'Plack::Builder');
$app = $builder->to_app($app);
ok $app;

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/app/foo/bar");
    ok $res->header('X-Runtime');
    is $res->header('X-Framework'), 'Plack::Builder';
    is $res->content, "it's ok";
};

package MyMiddleware;
use base 'Plack::Middleware';

sub call { 
    my($self, $env) = @_;
    my $res = $self->app->($env);
    unshift @{$res->[2]}, "it's ";
    return $res;
};
