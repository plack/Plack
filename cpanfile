requires 'perl', '5.008001';

requires 'Devel::StackTrace', '1.23';
requires 'Devel::StackTrace::AsHTML', '0.11';
requires 'File::ShareDir', '1.00';
requires 'Filesys::Notify::Simple';
requires 'HTTP::Body', '1.06';
requires 'HTTP::Message', '5.814';
requires 'Hash::MultiValue', '0.05';
requires 'LWP::UserAgent', '5.814';
requires 'Pod::Usage', '1.36';
requires 'Stream::Buffered', '0.02';
requires 'Test::TCP', '1.02';
requires 'Try::Tiny';
requires 'URI', '1.59';
requires 'parent';
requires 'Apache::LogFormat::Compiler', '0.12';

on test => sub {
    requires 'Test::More', '0.88';
    requires 'Test::Requires';
};

on develop => sub {
    recommends 'FCGI';
    recommends 'FCGI::ProcManager';
    recommends 'MIME::Types';
    recommends 'Authen::Simple::Passwd';
    recommends 'CGI::Emulate::PSGI';
    recommends 'CGI::Compile';
    recommends 'IO::Handle::Util';
    recommends 'LWP::Protocol::http10';
    recommends 'Log::Log4perl';
    recommends 'HTTP::Server::Simple::PSGI';
    recommends 'HTTP::Request::AsCGI';
};
