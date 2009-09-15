use HTTP::Engine;
use MyApp;
my $app = MyApp->new;

my $engine; $engine = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => sub { $app->request_handler(@_) },
    },
);

my $handler = sub { $engine->run(@_) };
