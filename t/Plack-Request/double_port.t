use Test::More;
use Plack::Test;
use Plack::Request;
use HTTP::Request::Common;

$Plack::Test::Impl = 'Server';
local $ENV{PLACK_SERVER} = "HTTP::Server::PSGI";

my $app = sub {
    my $req = Plack::Request->new(shift);
    return [200, [], [ $req->uri ]];
};

test_psgi app => $app, client => sub {
    my $cb = shift;
    my $res = $cb->(GET "http://localhost/foo");
    ok $res->content !~ /:\d+:\d+/;
};

done_testing;


