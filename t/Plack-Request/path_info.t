use strict;
use Test::More;
use Plack::Test;
use Plack::App::URLMap;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

my $path_app = sub {
    my $req = Plack::Request->new(shift);
    my $res = $req->new_response(200);
    $res->content_type('text/plain');
    $res->content($req->path_info);
    return $res->finalize;
};

my $app = Plack::App::URLMap->new;
$app->map("/foo" => $path_app);
$app->map("/" => $path_app);

test_psgi app => $app->to_app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/foo");
    is $res->content, '';

    $res = $cb->(GET "http://localhost/foo/bar");
    is $res->content, '/bar';

    $res = $cb->(GET "http://localhost/xxx/yyy");
    is $res->content, '/xxx/yyy';
};

done_testing;
