use strict;
use warnings;
use Test::More;
use Plack::Middleware::StackTrace;
use Plack::Test;
use HTTP::Request::Common;

$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    eval { challenge() };
    die $@ if $@;
};

sub challenge {
    die "oops";
}

my $wrapped = Plack::Middleware::StackTrace->wrap($app, no_print_errors => 1);

test_psgi $wrapped, sub {
    my $cb = shift;

    my $req = GET "/";
    my $res = $cb->($req);

    is $res->code, 500;
    like $res->content, qr/main::challenge/;
};

done_testing;

