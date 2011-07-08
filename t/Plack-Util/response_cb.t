use strict;
use warnings;
use Plack::Util;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

$Plack::Test::Impl = "Server";

my $app = sub {
    my $env = shift;
    return sub {
        my $respond = shift;
        my $writer = $respond->([200, [ 'Content-Type' => 'text/plain' ]]);
        $writer->write('foo');
        $writer->write('bar');
        $writer->close;
    };
};

my $mw = sub {
    my $env = shift;
    my $res = $app->($env);
    Plack::Util::response_cb($res, sub {
        my $res = shift;
        return sub {
            my $chunk = shift;
            return $chunk;
        }
    });
};

test_psgi $mw, sub {
    my $cb = shift;

    my $res = $cb->(GET "/");
    is $res->content, 'foobar';
};

done_testing;
