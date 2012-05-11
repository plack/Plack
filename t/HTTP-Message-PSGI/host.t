use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI qw(req_to_psgi);
use HTTP::Request;

{
    my $req = HTTP::Request->new(GET => "http://example.com/");
    my $env = req_to_psgi $req;

    is $env->{HTTP_HOST}, 'example.com';
    is $env->{PATH_INFO}, '/';
}

{
    my $req = HTTP::Request->new(GET => "http://example.com:345/");
    my $env = req_to_psgi $req;

    is $env->{HTTP_HOST}, 'example.com:345';
    is $env->{PATH_INFO}, '/';
}

{
    my $req = HTTP::Request->new(GET => "/");
    $req->header('Host' => "perl.com");
    my $env = req_to_psgi $req;

    is $env->{HTTP_HOST}, 'perl.com';
    is $env->{PATH_INFO}, '/';
}

done_testing;



