use CGI::Application::PSGI;
use MyApp;

my $handler = sub {
    my $env = shift;
    my $app = MyApp->new({ QUERY => CGI::PSGI->new($env) });
    CGI::Application::PSGI->run($app);
};
