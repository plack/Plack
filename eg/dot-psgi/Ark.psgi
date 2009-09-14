use MyApp;

my $app = MyApp->new;
$app->setup;

my $handler = $app->psgi_handler;
