use strict;
use warnings;
use Test::More;
use Plack::Builder;
use HTTP::Request::Common;
use Plack::Test;

my $handler = builder {
    enable 'ConditionalGET';

    sub {
        my $env = shift;
        return sub {
            my $writer = shift->( [ 200, [
                'Content-Type' => 'text/plain',
                'ETag' => 'DEADBEEF',
            ] ] );
            $writer->write($_) for ( qw( kling klang klong ) );
            $writer->close;
        };

    };
};

test_psgi $handler, sub {
    my $cb = shift;

    my $res = $cb->( GET "http://localhost/streaming-klingklangklong" );
    is $res->code, 200, 'Response HTTP status';
    is $res->content, 'klingklangklong', 'Response content';

    # the middleware does not support streaming interface but make it at least not die
    $res = $cb->( GET
        "http://localhost/streaming-klingklangklong",
        'If-None-Match' => 'DEADBEEF'
    );
    is $res->code, 200, 'Response HTTP status';
    is $res->content, 'klingklangklong', 'Response content';
};

done_testing;

