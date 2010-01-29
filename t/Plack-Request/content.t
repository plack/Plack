use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;

my $app = sub {
    my $req = Plack::Request->new(shift);
    is $req->content, 'body';
    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = HTTP::Request->new(POST => "/");
    $req->content("body");
    $req->content_length(4);
    $cb->($req);
};

done_testing;

