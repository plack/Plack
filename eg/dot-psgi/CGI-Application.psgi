use MyApp;
use CGI::Application::PSGI;

my $app = sub {
    my $env = shift;
    local *ENV = $env;

    my $webapp = MyApp->new;
    CGI::Application::PSGI->run($webapp);
};
