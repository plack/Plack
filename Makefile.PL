sub author_tests  { }
sub use_test_base { warn "You need to install Test::Base to run make test from git clone" }
sub readme_from   { }

use inc::Module::Install;
name 'Plack';
all_from 'lib/Plack.pm';
readme_from 'lib/Plack.pm';

requires 'Class::Accessor::Fast';
requires 'LWP'; # HTTP::Status, HTTP::Headers and HTTP::Request
requires 'HTTP::Body';
requires 'URI';
requires 'HTTP::Request::AsCGI';
requires 'HTTP::Parser::XS', 0.03;
requires 'CGI::Simple::Cookie'; # Plack::Response
requires 'Pod::Usage';  # plackup

requires 'CGI::ExceptionManager'; # Middleware::DebugScreen
requires 'Path::Class'; # Middleware::Static
requires 'MIME::Types'; # Middleware::Static

build_requires 'Test::More', 0.88;
build_requires 'Test::TCP', 0.11;
test_requires 'Test::Requires';

#author_requires 'AnyEvent';
#author_requires 'Catalyst::Runtime';
#author_requires 'Mojo';
#author_requires 'HTTP::Server::Simple';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t';
author_tests 'xt';

use_test_base;
auto_include;
WriteAll;
