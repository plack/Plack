use MyApp;
my $app = MyApp->new;
return sub { $app->run };
