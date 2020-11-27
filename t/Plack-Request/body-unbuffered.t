use strict;
use warnings;
use Test::More;
use Plack::Test;
use Plack::Request;
use Plack::Util;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;

    $env->{'psgix.input.buffered'} = 0;

    my $input = $env->{'psgi.input'};
    $env->{'psgi.input'} = Plack::Util::inline_object
      read => sub { $input->read(@_) };
    
    my $req = Plack::Request->new($env);
    is $req->content, '{}';

    $req->new_response(200)->finalize;
};

test_psgi $app, sub {
    my $cb = shift;

    # empty Content-Type
    my $req = POST "/";
    $req->content_type("");
    $req->content("{}");
    $req->content_length(2);

    my $res = $cb->($req);
    ok $res->is_success or diag $res->as_string;
};

done_testing;
