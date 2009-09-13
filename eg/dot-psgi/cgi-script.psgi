use CGI::Emulate::PSGI;
my $handler = CGI::Emulate::PSGI->handler(sub { do "hello.cgi" });
