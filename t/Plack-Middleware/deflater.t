use strict;
use Test::More;
use Test::Requires qw(IO::Handle::Util);
use IO::Handle::Util qw(:io_from);
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::Deflater;
$Plack::Test::Impl = "Server";

my @app = (
    sub { [ 200, [], [ 'Hello World' ] ] },
    sub { [ 200, [], [ 'Hello ', 'World' ] ] },
    sub { [ 200, [], [ 'Hello ', '', 'World' ] ] },
    sub { [ 200, [], io_from_array [ 'Hello World' ] ] },
    sub { [ 200, [], io_from_array [ 'Hello', ' World' ] ] },
    sub { [ 200, [], io_from_array [ 'Hello', '', ' World' ] ] },
);

my $app = sub { (shift @app)->(@_) };

test_psgi app => Plack::Middleware::Deflater->wrap($app), client => sub {
    my $cb = shift;

    local *HTTP::Request::decodable = sub { wantarray ? ('gzip') : 'gzip' };
    for (0..$#app) {
        my $req = GET "http://localhost/";
        $req->accept_decodable;
        my $res = $cb->($req);
        is $res->decoded_content, 'Hello World';
        is $res->content_encoding, 'gzip';
    }
};

done_testing;
