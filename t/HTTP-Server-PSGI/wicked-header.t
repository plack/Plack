use strict;
use warnings;

use Plack::Test;
use Test::More;

test_psgi app => sub {
    return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'X-Foo' => undef ] ];
    },
    client => sub {
    my $cb = shift;
    {
        my $req = HTTP::Request->new( POST => '/wicked/1' );
        ok( my $res = $cb->($req) );
        is $res->header('X-Foo'), undef;
        ok $res->is_success;
        is $res->code, 200;
    }
    };

done_testing();
