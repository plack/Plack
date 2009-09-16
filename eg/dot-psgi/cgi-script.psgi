use CGI::Emulate::PSGI;
my $handler = CGI::Emulate::PSGI->handler(sub {
    do "hello.cgi";
    CGI::initialize_globals() if defined &CGI::initialize_globals;
});
