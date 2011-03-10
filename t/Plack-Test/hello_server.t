use Test::More;
use Plack::Test;

$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

test_psgi
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/hello");
        my $res = $cb->($req);
        is $res->content, 'Hello World';
        is $res->content_type, 'text/plain';
        is $res->code, 200;
    },
    app => sub {
        my $env = shift;
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
    };

done_testing;
