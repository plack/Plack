use strict;
use warnings;
use Test::More;
use Test::Requires qw( Path::Class );
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Cwd;

my $handler = builder {
    enable "Plack::Middleware::XSendfile";
    enable "Plack::Middleware::Static",
        path => qr/./, root => ".";
    sub { };
};

test_psgi app => $handler, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/t/00_compile.t", 'X-Sendfile-Type' => 'X-Sendfile';
        my $res = $cb->($req);
        is $res->content_type, 'application/x-troff';;
        is $res->header('X-Sendfile'), Cwd::realpath("t/00_compile.t");
        is $res->content, '';
    }
};

test_psgi(
    app => sub { return [ 200, [ 'X-Sendfile' => '/foo/bar.txt' ], [] ] },
    client => sub {
        my $cb = shift;
        my $res = $cb->(GET "http://localhost/foo", 'X-Sendfile-Type' => 'X-Sendfile');
        is $res->header('X-Sendfile'), '/foo/bar.txt', 'pass through app header';
    },
);

done_testing;
