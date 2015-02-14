requires 'perl', '5.008001';

requires 'Devel::StackTrace', '1.23';
requires 'Devel::StackTrace::AsHTML', '0.11';
requires 'File::ShareDir', '1.00';
requires 'Filesys::Notify::Simple';
requires 'HTTP::Body', '1.06';
requires 'HTTP::Message', '5.814';
requires 'Hash::MultiValue', '0.05';
requires 'Pod::Usage', '1.36';
requires 'Stream::Buffered', '0.02';
requires 'Test::TCP', '2.00';
requires 'Try::Tiny';
requires 'URI', '1.59';
requires 'parent';
requires 'Apache::LogFormat::Compiler', '0.12';
requires 'HTTP::Tiny', 0.034;

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Requires';
    suggests 'Authen::Simple::Passwd';
    suggests 'MIME::Types';
    suggests 'CGI::Emulate::PSGI';
    suggests 'CGI::Compile';
    suggests 'IO::Handle::Util';
    suggests 'LWP::Protocol::http10';
    suggests 'Log::Log4perl';
    suggests 'HTTP::Server::Simple::PSGI';
    suggests 'HTTP::Request::AsCGI';
    suggests 'LWP::UserAgent', '5.814';
    suggests 'Module::Refresh';
};

on runtime => sub {
    suggests 'FCGI';
    suggests 'FCGI::ProcManager';
    suggests 'CGI::Emulate::PSGI';
    suggests 'CGI::Compile';
    suggests 'IO::Handle::Util';
    suggests 'LWP::UserAgent', '5.814';
};

