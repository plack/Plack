use AnyEvent;
my $app = sub {
    my($env, $start_response) = @_;
    die "This app needs psgi.async backend (AnyEvent or Danga::Socket + Danga::Socket::AnyEvent)"
        unless $env->{'psgi.async'};

    my $writer = $start_response->(200, ['X-Foo' => 'bar']);
    my $streamer; $streamer = AnyEvent->timer(
        after => 0,
        interval => 1,
        cb => sub {
            scalar $streamer;
            $writer->write(time() . "\n");
        },
    );

    my $close_w; $close_w = AnyEvent->timer(
        after => 5,
        cb => sub {
            scalar $close_w;
            undef $streamer; # cancel
            $writer->write("DONE\n");
            $writer->close;
        },
    );

    return [];
};
