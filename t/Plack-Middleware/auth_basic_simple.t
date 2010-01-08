use Test::More;
use Test::Requires qw(Authen::Simple::Passwd);
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $_[0]->{REMOTE_USER}" ] ] };
$app = builder {
    enable "Auth::Basic", authenticator => Authen::Simple::Passwd->new(path => "t/Plack-Middleware/htpasswd");
    $app;
};

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->code, 401;

    my $req = GET "http://localhost/", "Authorization" => "Basic YWRtaW46czNjcjN0";
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, "Hello admin";

    local $^W = 0;
    $req = GET "http://localhost/", "Authorization" => "Basic bogus";
    $res = $cb->($req);
    is $res->code, 401;
};
done_testing;

