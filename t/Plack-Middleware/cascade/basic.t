use Plack::Test;
use Test::More;

use Plack::App::Cascade;
use Plack::App::URLMap;
use Plack::App::File;
use HTTP::Request::Common;

my $cascade = Plack::App::Cascade->new;
$cascade->add( Plack::App::File->new(root => "t/Plack-Middleware")->to_app );
$cascade->add( Plack::App::File->new(root => "t/Plack-Util")->to_app );

my $app = Plack::App::URLMap->new;
$app->map("/static", $cascade);

test_psgi app => $app->to_app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/static/access_log.t");
    is $res->code, 200;

    $res = $cb->(GET "http://localhost/static/foo");
    is $res->code, 404;

    $res = $cb->(GET "http://localhost/static/foreach.t");
    is $res->code, 200;
};

done_testing;
