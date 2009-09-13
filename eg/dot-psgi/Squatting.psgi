use MyApp 'On::PSGI';
MyApp->init;

my $handler = sub {
    my $env = shift;
    MyApp->psgi($env);
};
