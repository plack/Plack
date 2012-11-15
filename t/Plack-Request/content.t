use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;

my $app = sub {
    my $env = shift;

    my $req = Plack::Request->new($env);
    is $req->content, 'body';

    # emulate other PSGI apps that reads from input, but not reset
    $env->{'psgi.input'}->read(my($dummy), $env->{CONTENT_LENGTH}, 0);

    $req = Plack::Request->new($env);
    is $req->content, 'body';

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    my $req = HTTP::Request->new(POST => "/");
    $req->content("body");
    $req->content_type('text/plain');
    $req->content_length(4);
    $cb->($req);
};

done_testing;

