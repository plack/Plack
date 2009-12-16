package Hello;

sub to_app {
    return sub {
        return [200, ['Content-Type', 'text/plain'], ['Hello']];
    };
}

__PACKAGE__->to_app;


