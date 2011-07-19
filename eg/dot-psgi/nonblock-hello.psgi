use AnyEvent;

my $app = sub {
    my $env = shift;

    warn "This app needs a server that supports psgi.streaming and psgi.nonblocking"
        unless $env->{'psgi.streaming'} && $env->{'psgi.nonblocking'};

    return sub {
        my $respond = shift;
        my $w = $respond->([ 200, ['Content-Type' => 'text/plain'] ]);
        $w->write("Hello\n");
        my $t; $t = AE::timer 2, 0, sub {
            undef $t;
            $w->write("World\n");
            $w->close;
        };
    };
};
