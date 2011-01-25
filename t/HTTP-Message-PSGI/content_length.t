use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI qw(req_to_psgi);
use HTTP::Request;

my $content = "{'foo':'bar'}";
my $req = HTTP::Request->new(POST => "http://localhost/post", [ "Content-Type", "application/json" ], $content);

my $env = req_to_psgi $req;

is $env->{CONTENT_LENGTH}, 13;
$env->{"psgi.input"}->read(my $buf, 13);

is $buf, $content;

done_testing;



