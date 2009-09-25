use MyApp; # should inherit from CGI::Application::PSGI

my $handler = sub {
    my $env = shift;
    my $webapp = MyApp->new($env)->run;
};
