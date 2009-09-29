use Test::More;
use Plack::Test::MockHTTP;

test_mock_http
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
