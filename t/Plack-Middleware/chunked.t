use strict;
use Test::More;
use Test::Requires qw(IO::Handle::Util);
use IO::Handle::Util qw(:io_from);
use HTTP::Request::Common;
use Plack::Test;
use Plack::Middleware::Chunked;
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

test_psgi app => Plack::Middleware::Chunked->wrap($app), client => sub {
    my $cb = shift;

    for (0..$#app) {
        my $res = $cb->(GET "http://localhost/");
        is $res->content, 'Hello World';
        is $res->decoded_content, 'Hello World';
        is $res->header('client-transfer-encoding'), 'chunked';
    }
};

done_testing;
