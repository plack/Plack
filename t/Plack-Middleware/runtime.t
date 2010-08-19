use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

plan skip_all => "Skipping on $^O platform" if $^O eq 'MSWin32';

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

    ok $res->header('X-Runtime') >= 0.5;
};

done_testing;
