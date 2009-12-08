use Plack::Test;
use Test::More;
use HTTP::Request::Common;
$Plack::Test::Impl = "Server";

my $app = sub { return [ 200, [], [ "Hello" ] ] };

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->content, "Hello";
};

done_testing;
