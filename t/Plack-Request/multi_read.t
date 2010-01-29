use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    is $req->content, 'foo=bar';
    is $req->content, 'foo=bar';

    $req = Plack::Request->new($env);
    is $req->content, 'foo=bar';
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(POST "/", { foo => "bar" });
    ok $res->is_success;
};

done_testing;
