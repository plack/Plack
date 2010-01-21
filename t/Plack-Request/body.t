use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub {
    my $req = Plack::Request->new(shift);
    is $req->content, 'foo=bar';
    is_deeply $req->body_params, { foo => 'bar' };
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;
    $cb->(POST "/", { foo => "bar" });
};

done_testing;
