use strict;
use Plack::Util;
use Plack::Test;
use HTTP::Request::Common;
use Test::More;

{
    my $app = Plack::Util::load_psgi("t/Plack-Util/hello.psgi");
    ok $app;

    test_psgi $app, sub {
        is $_[0]->(GET "/")->content, "Hello";
    };
}

{
    use lib "t/Plack-Util";
    my $app = Plack::Util::load_psgi("Hello");
    ok $app;
    test_psgi $app, sub {
        is $_[0]->(GET "/")->content, "Hello";
    };
}




done_testing;
