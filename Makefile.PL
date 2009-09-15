sub author_tests { die "You need to install Module::Install::AuthorTests to build from git clone\n" }

use inc::Module::Install;
name 'Plack';
all_from 'lib/Plack.pm';

requires 'Class::Accessor::Fast';
requires 'LWP'; # HTTP::Status, HTTP::Headers and HTTP::Request
requires 'HTTP::Body';
requires 'URI';
requires 'HTTP::Request::AsCGI';
requires 'HTTP::Parser::XS';

build_requires 'Test::More';
build_requires 'Test::TCP' => '0.09';
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
