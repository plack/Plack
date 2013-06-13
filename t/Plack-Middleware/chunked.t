use strict;
use Test::More;
use Test::Requires qw(IO::Handle::Util LWP::UserAgent LWP::Protocol::http10);
use IO::Handle::Util qw(:io_from);
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::Chunked;

$Plack::Test::Impl = "Server";

local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my @app = (
    sub { [ 200, [], [ 'Hello World' ] ] },
    sub { [ 200, [], [ 'Hello ', 'World' ] ] },
    sub { [ 200, [], [ 'Hello ', '', 'World' ] ] },
    sub { [ 200, [], io_from_array [ 'Hello World' ] ] },
    sub { [ 200, [], io_from_array [ 'Hello', ' World' ] ] },
    sub { [ 200, [], io_from_array [ 'Hello', '', ' World' ] ] },
);

@app = (@app, @app); # for 1.0 and 1.1

my $app = sub { (shift @app)->(@_) };

test_psgi
    ua => LWP::UserAgent->new, # force LWP
    app => Plack::Middleware::Chunked->wrap($app), client => sub {
    my $cb = shift;

    for my $proto (qw( HTTP/1.1 HTTP/1.0 )) {
        my $is_http_10 = $proto eq 'HTTP/1.0';
        if ($is_http_10) {
            LWP::Protocol::implementor('http', 'LWP::Protocol::http10');
        }

        for (1..@app/2) {
            my $req = GET "http://localhost/";
            $req->protocol($proto);
            my $res = $cb->($req);
            is $res->content, 'Hello World';
            is $res->decoded_content, 'Hello World';
            if ($is_http_10) {
                isnt $res->header('client-transfer-encoding'), 'chunked', 'Chunked shouldn\'t be used in HTTP/1.0';
            } else {
                is $res->header('client-transfer-encoding'), 'chunked';
            }
        }
    }
};

done_testing;
