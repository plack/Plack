use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $_[0]->{REMOTE_USER}" ] ] };
$app = builder {
    enable "Auth::Basic", authenticator => \&cb,
                          path          => qr{^/restricted};
    $app;
};

sub cb {
    my($username, $password) = @_;
    return $username eq 'admin' and $password eq 's3cr3t';
}

test_psgi $app, sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->code, 200;

    $res = $cb->(GET "http://localhost/stuff");
    is $res->code, 200;

    $res = $cb->(GET "http://localhost/restricted");
    is $res->code, 401;

    my $req = GET "http://localhost/restricted", "Authorization" => "Basic YWRtaW46czNjcjN0";
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, "Hello admin";

    $req = GET "http://localhost/restricted/stuff", "Authorization" => "Basic YWRtaW46czNjcjN0";
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, "Hello admin";
};
done_testing;

