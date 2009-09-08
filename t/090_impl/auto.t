use strict;
use Test::More;
use Plack::Loader;

$ENV{PSGI_PLACK_IMPL} = "CGI";

use HTTP::Request::AsCGI;
use HTTP::Request::Common;

my $app = sub {
    my $env = shift;
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello" ] ];
};

{
    my $c = HTTP::Request::AsCGI->new(GET "http://localhost/")->setup;
    Plack::Loader->auto->run($app);
    like $c->response->content, qr/Hello/;
}

done_testing;
