use CGI::Emulate::PSGI;
my $handler = CGI::Emulate::PSGI->handler(sub {
    do "hello.cgi";
    CGI::_reset_globals() if %CGI::;
});
