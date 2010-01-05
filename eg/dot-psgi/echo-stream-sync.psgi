my $app = sub {
    my $env = shift;

    return sub {
        my $respond = shift;
        my $w = $respond->([ 200, ['X-Foo' => 'bar', 'Content-Type' => 'text/plain'] ]);
        for (1..5) {
            sleep 1;
            $w->write(time . "\n");
        }
    };
};
