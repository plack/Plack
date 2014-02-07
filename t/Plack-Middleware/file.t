use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use Plack::App::File;
use FindBin qw($Bin);

my $app = Plack::App::File->new(file => 'Changes');

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    like $res->content, qr/Plack/;

    $res = $cb->(GET "/whatever");
    is $res->content_type, 'text/plain';
    is $res->code, 200;
};

my $app_content_type = Plack::App::File->new(
    file => 'Changes',
    content_type => 'text/x-changes'
);

test_psgi $app_content_type, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    like $res->content, qr/Plack/;

    $res = $cb->(GET "/whatever");
    is $res->content_type, 'text/x-changes';
    is $res->code, 200;
};

my $app_secure = Plack::App::File->new(root => $Bin);

test_psgi $app_secure, sub {
    my $cb = shift;

    my $res = $cb->(GET "/file.t");
    is $res->code, 200;
    like $res->content, qr/We will find for this literal string/;

    my $res = $cb->(GET "/../Plack-Middleware/file.t");
    is $res->code, 403;
    is $res->content, 'forbidden';

    for my $i (1..100) {
        $res = $cb->(GET "/file.t" . ("/" x $i));
        is $res->code, 404;
        is $res->content, 'not found';
    }
};

done_testing;
