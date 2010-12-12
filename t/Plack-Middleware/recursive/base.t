use strict;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Recursive;


my $app = sub {
    my $env = shift;

    if ($env->{PATH_INFO} eq '/forwarded') {
        is_deeply $env->{'plack.recursive.old_path_info'}, [ '/' ];
        return [ 200, [ 'Content-Type', 'text/plain' ], [ "Hello $env->{QUERY_STRING}" ] ];
    }

    return $env->{'plack.recursive.include'}->("/forwarded?q=bar");
};

$app = Plack::Middleware::Recursive->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    is $res->content, "Hello q=bar";
};

done_testing;
