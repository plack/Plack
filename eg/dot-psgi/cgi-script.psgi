use CGI::Emulate::PSGI;
CGI::Emulate::PSGI->handler(sub { do "hello.cgi" });
