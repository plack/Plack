use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;

my $app = builder {
    enable "Runtime";
    sub {
        sleep 1;
        return [200, ['Content-Type'=>'text/html'], ["Hello"]];
    };
};

test_psgi $app, sub {
    my $cb = shift;
    my $res = $cb->(GET "/");

    ok $res->header('X-Runtime') > 1;
};

done_testing;
