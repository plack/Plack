use Test::More;
use Plack::Test::Server;

test_server(
    client => sub {
        my $cb = shift;
        my $req = HTTP::Request->new(GET => "http://localhost/hello");
        my $res = $cb->($req);
        like $res->content, qr/Hello World/;
    },
    app => sub {
        my $env = shift;
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello World" ] ];
    },
);

done_testing;
