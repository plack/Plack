use AnyEvent;
my $app = sub {
    my $env = shift;

    warn "This app would block currently when doing the timer sleep. Later will be updated using IO::Writer"
        if $env->{'psgi.nonblocking'};

    my $count;
    my $body = Plack::Util::inline_object
        getline => sub {
            return if $count++ > 5;
            sleep 1;
            return time . "\n";
        },
        close => sub {};

    return [ 200, ['X-Foo' => 'bar'], $body ];
};
