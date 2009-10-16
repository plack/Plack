use strict;
use Test::Base;
use Plack::Builder;

filters {
    app => 'eval',
    env => 'yaml',
    headers => 'yaml',
};

plan tests => 2 * blocks;

run {
    my $block = shift;
    my $handler = builder {
        enable "Plack::Middleware::Writer";
        $block->app;
    };
    my $res = $handler->($block->env);
    is_deeply $res->[1], $block->headers, "headers passed through";
    is join("", @{ $res->[2] }) . "\n", $block->body, "body accumulated";
};

__END__

=== simple write
--- app
sub {
    return sub {
        $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ]);
    }
}
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- text/plain
--- body
OK

=== iterative write
--- app
sub {
    return sub {
        my $writer = $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ]]);

        $writer->write("O");
        $writer->write("K");
        $writer->close();
    }
}
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- text/plain
--- body
OK

=== iterative write
--- app
sub {
    return sub {
        my $writer = $_[0]->([ 200, [ 'Content-Type' => 'text/plain' ]]);

        my @queue = qw(O K);

        $writer->poll_cb(sub {
            if ( @queue ) {
                $writer->write(shift @queue);
            } else {
                $writer->close();
            }
        });
    }
}
--- env
REQUEST_METHOD: GET
--- headers
- Content-Type
- text/plain
--- body
OK
