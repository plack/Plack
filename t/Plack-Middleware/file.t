use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;
use Plack::App::File;

my $app = Plack::App::File->new(file => 'README');

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    like $res->content, qr/Plack/;

    $res = $cb->(GET "/whatever");
    is $res->content_type, 'text/plain';
    is $res->code, 200;
    my $last_modified = $res->header('Last-Modified');
    like $last_modified, qr/ GMT$/;

    $res = $cb->(GET "/whatever", 'If-Modified-Since' => $last_modified);
    is $res->code, 304;
    is $res->header('Content-Length'), undef;
    is $res->header('Content-Type'), undef;
    is $res->header('Last-Modified'), undef;
};

my $app_content_type = Plack::App::File->new(
    file => 'README',
    content_type => 'text/x-readme'
);

test_psgi $app_content_type, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->code, 200;
    like $res->content, qr/Plack/;

    $res = $cb->(GET "/whatever");
    is $res->content_type, 'text/x-readme';
    is $res->code, 200;
};



done_testing;
