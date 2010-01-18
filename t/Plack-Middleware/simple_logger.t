use strict;
use Plack::Test;
use Test::More;
use Plack::Middleware::SimpleLogger;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    my $errors;
    $env->{'psgi.errors'} = do { open my $io, ">", \$errors; $io };

    $env->{'psgi.logger'}->(debug => "This is debug");
    $env->{'psgi.logger'}->(info => "This is info");

    return [ 200, [], [$errors] ];
};

$app = Plack::Middleware::SimpleLogger->wrap($app, level => "info");

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    like $res->content, qr/This is info/;
    unlike $res->content, qr/This is debug/;
};

done_testing;
