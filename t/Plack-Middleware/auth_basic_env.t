use Test::More;
use Plack::Test;
use Plack::Builder;
use Plack::Request;
use HTTP::Request::Common;

my $app = sub { return [ 200, [ 'Content-Type' => 'text/plain' ], [ "Hello $_[0]->{REMOTE_USER}" ] ] };
$app = builder {
    enable "Auth::Basic", authenticator => \&cb;
    $app;
};

sub cb {
    my($username, $password, $env) = @_;
    my $req = Plack::Request->new($env);
    if ($req->path eq '/') {
        return $username eq 'admin' && $password eq 's3cr3t';
    }
    else {
        return $username eq 'user' && $password eq 's0m3th1ngel5e';
    }
}

test_psgi app => $app, client => sub {
    my $cb = shift;

    {
        my $res = $cb->(GET "http://localhost/");
        is $res->code, 401;
    }

    {
        my $req = GET "http://localhost/", "Authorization" => "Basic YWRtaW46czNjcjN0";
        my $res = $cb->($req);
        is $res->code, 200;
        is $res->content, "Hello admin";
    }

    {
        my $req = GET "http://localhost/", "Authorization" => "Basic dXNlcjpzMG0zdGgxbmdlbDVl";
        my $res = $cb->($req);
        is $res->code, 401;
    }

    {
        my $req = GET "http://localhost/foo", "Authorization" => "Basic YWRtaW46czNjcjN0";
        my $res = $cb->($req);
        is $res->code, 401;
    }

    {
        my $req = GET "http://localhost/foo", "Authorization" => "Basic dXNlcjpzMG0zdGgxbmdlbDVl";
        my $res = $cb->($req);
        is $res->code, 200;
        is $res->content, "Hello user";
    }
};
done_testing;

