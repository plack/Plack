use AnyEvent;
my $app = sub {
    my $env = shift;

    warn "This app needs a server that supports psgi.streaming"
        unless $env->{'psgi.streaming'};

    return sub {
        my $respond = shift;
        my $w = $respond->([ 200, ['X-Foo' => 'bar', 'Content-Type' => 'text/plain'] ]);
        my $t; $t = AE::timer 0, 1, sub {
            $t;
            # TODO handle client disconnect (broken pipe) and poll_cb
            $w->write(time . "\n");
        };
    };
};
