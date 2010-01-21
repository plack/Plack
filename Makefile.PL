sub author_tests  { }
sub use_test_base { warn "You need to install Test::Base to run make test from git clone" }
sub readme_from   { }
sub auto_set_repository { }

use inc::Module::Install;

name 'Plack';
all_from 'lib/Plack.pm';
readme_from 'lib/Plack.pm';

requires 'LWP', 5.814; # HTTP::Status, HTTP::Headers and HTTP::Request
requires 'URI';
requires 'Pod::Usage';  # plackup
requires 'File::ShareDir', '1.00'; # Plack::Test::Suite
requires 'Try::Tiny';
requires 'parent';

requires 'Devel::StackTrace'; # Middleware::StackTrace
requires 'Devel::StackTrace::AsHTML'; # Middleware::StackTrace

requires 'Filesys::Notify::Simple'; # plackup -r
requires 'Hash::MultiValue'; # Plack::Request

# TODO: they can go away once we create Plack-Middlewares dist
# Middleware::Static and App::File
requires 'Path::Class';

build_requires 'Test::More', 0.88;
build_requires 'Test::TCP', 0.11;
test_requires 'Test::Requires';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t';
author_tests 'xt';

install_share 'share';
install_script 'scripts/plackup';

use_test_base;
auto_include;
auto_install;
auto_set_repository;
WriteAll;

warn <<RECOMMENDS;

  This is Plack, PSGI toolkit containing servers, middleware and utils.

  To run the default backends faster with XS extensions, as well as run some server
  backends like Prefork and FCGI, you need to install additional Perl module dependencies,
  that are included in Task::Plack bundle. You're recommended to run

    cpan> install Task::Plack

  once this distribution is installed. Enjoy!

RECOMMENDS
