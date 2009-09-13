use MyApp;

my $app = MyApp->new;
$app->setup;

my $engine = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => $app->handler,
    },
);

my $handler = sub { $engine->run(@_) };
