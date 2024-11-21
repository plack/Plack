BEGIN {
  if ( $ENV{NO_NETWORK_TESTING} ) {
    print '1..0 # SKIP Network connections required for this test';
    exit;
  }
}

use Plack::Test;
use Test::More;
use HTTP::Request::Common;
$Plack::Test::Impl = "Server";
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub { return [ 200, [], [ "Hello" ] ] };

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");
    is $res->content, "Hello";
};

done_testing;
