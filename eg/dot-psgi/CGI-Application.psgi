use MyApp;
use CGI::Emulate::PSGI;
CGI::Emulate::PSGI->handler(
    sub { MyApp->new->run },
);
