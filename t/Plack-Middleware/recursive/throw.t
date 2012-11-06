use strict;
use Test::More;
use Plack::Test;
use HTTP::Request::Common;

use Plack::Middleware::Recursive;

my $app = sub {
    my $env = shift;

    if ($env->{PATH_INFO} eq '/forwarded2') {
        is_deeply $env->{'plack.recursive.old_path_info'}, [ '/', '/forwarded' ];
        return [ 200, [ 'Content-Type', 'text/plain' ], [ "Hello $env->{QUERY_STRING}" ] ];
    } elsif ($env->{PATH_INFO} eq '/forwarded') {
        Plack::Recursive::ForwardRequest->throw("/forwarded2?q=bar");
    } elsif ($env->{PATH_INFO} eq '/die') {
        die "Foo";
    }

    Plack::Recursive::ForwardRequest->throw("/forwarded?q=bar");
};

$app = Plack::Middleware::Recursive->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    is $res->content, "Hello q=bar";

    $res = $cb->(GET "/die");
    is $res->code, 500;
    like $res->content, qr/Foo at /;
};

done_testing;
