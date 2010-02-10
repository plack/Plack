use strict;
use Test::More;
use Plack::Builder;

my @tests = (
    {
        app => sub {
            return sub {
                $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ]);
            },
        },
        env => { REQUEST_METHOD => 'GET' },
        headers => [ 'Content-Type' => 'text/plain' ],
        body => 'OK',
    },
    {
        app => sub {
            return sub {
                my $writer = $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ]]);
                $writer->write("O");
                $writer->write("K");
                $writer->close();
            },
        },
        env => { REQUEST_METHOD => 'GET' },
        headers => [ 'Content-Type', 'text/plain' ],
        body => 'OK',
    },
);


plan tests => 2 * @tests;

for my $block (@tests) {
    my $handler = builder {
        enable "BufferedStreaming";
        $block->{app};
    };
    my $res = $handler->($block->{env});
    is_deeply $res->[1], $block->{headers}, "headers passed through";
    is join("", @{ $res->[2] }), $block->{body}, "body accumulated";
};
