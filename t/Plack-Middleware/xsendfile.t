use strict;
use warnings;
use Test::More;
use HTTP::Request::Common;
use Plack::Builder;
use Plack::Test;
use Cwd;

sub is_wo_case($$;$) {
    is lc $_[0], lc $_[1], $_[2];
}

my $handler = builder {
    enable "Plack::Middleware::XSendfile";
    enable "Plack::Middleware::Static",
        path => qr/./, root => ".";
    sub { };
};

test_psgi app => $handler, client => sub {
    my $cb = shift;

    {
        my $req = GET "http://localhost/t/test.txt", 'X-Sendfile-Type' => 'X-Sendfile';
        my $res = $cb->($req);
        is $res->content_type, 'text/plain';;
        is_wo_case $res->header('X-Sendfile'), Cwd::realpath("t/test.txt"); # wo_case for Win32--
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
