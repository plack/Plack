use Test::More;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $_[0]->{REMOTE_USER}" ] ] };
$app = builder {
    enable "Auth::Basic", authenticator => \&cb;
    $app;
};

my %map = (
  admin => 's3cr3t',
  john  => 'foo:bar',
);

sub cb {
    my($username, $password) = @_;
    return $map{$username} && $password eq $map{$username};
}

test_psgi app => $app, client => sub {
    my $cb = shift;

    my $res = $cb->(GET "http://localhost/");
    is $res->code, 401;

    my $req = GET "http://localhost/", "Authorization" => "Basic YWRtaW46czNjcjN0";
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, "Hello admin";

    $req = GET "http://localhost/", "Authorization" => "Basic am9objpmb286YmFy";
    $res = $cb->($req);
    is $res->code, 200;
    is $res->content, "Hello john";
};
done_testing;

