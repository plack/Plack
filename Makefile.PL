sub author_tests { die "You need to install Module::Install::AuthorTests and Test::Base to build from git clone\n" }

use inc::Module::Install;
name 'Plack';
all_from 'lib/Plack.pm';

requires 'Class::Accessor::Fast';
requires 'LWP'; # HTTP::Status, HTTP::Headers and HTTP::Request
requires 'HTTP::Body';
requires 'URI';
requires 'HTTP::Request::AsCGI';
requires 'HTTP::Parser::XS';
requires 'Pod::Usage';

requires 'Path::Class'; # Middleware::Static
requires 'MIME::Types'; # Middleware::Static

build_requires 'Test::More';
build_requires 'Test::TCP';
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
