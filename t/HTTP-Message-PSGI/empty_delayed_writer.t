use strict;
use warnings;
use Test::More;
use HTTP::Message::PSGI;
use HTTP::Request;
use HTTP::Response;

my $app = sub {
  my ($env) = @_;
  return sub {
    my ($responder) = @_;
    my $writer = $responder->([ 200, [] ]);
    $writer->close;
  };
};

my $env = req_to_psgi(HTTP::Request->new(POST => "http://localhost/post", [ ], 'hello'));

my $response = HTTP::Response->from_psgi($app->($env));

is($response->content, '', 'delayed writer without write gives empty content');

done_testing;
