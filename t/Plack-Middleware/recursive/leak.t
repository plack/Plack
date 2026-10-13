use strict;
use Test::More;
use Scalar::Util qw(weaken);

use Plack::Middleware::Recursive;

my $app = Plack::Middleware::Recursive->wrap(sub {
    my $env = shift;
    if ($env->{PATH_INFO} eq '/include') {
        return $env->{'plack.recursive.include'}->("/included");
    }
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ "ok" ] ];
});

for my $path ('/', '/include') {
    my $weak;
    {
        my $env = { PATH_INFO => $path, REQUEST_METHOD => 'GET' };
        my $res = $app->($env);
        is $res->[0], 200;
        $weak = $env;
        weaken $weak;
    }
    ok !defined $weak, "env is freed after request to $path";
}

done_testing;
