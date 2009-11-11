sub author_tests  { }
sub use_test_base { warn "You need to install Test::Base to run make test from git clone" }
sub readme_from   { }
sub install_share { warn "You need to install Module::Install::Share to install from git clone" }
sub auto_set_repository { }

use inc::Module::Install;
use Module::AutoInstall;

name 'Plack';
all_from 'lib/Plack.pm';
readme_from 'lib/Plack.pm';

requires 'Class::Accessor::Fast';
requires 'LWP', 5.814; # HTTP::Status, HTTP::Headers and HTTP::Request
requires 'URI';
requires 'Pod::Usage';  # plackup
requires 'File::ShareDir', '1.00'; # Plack::Test::Suite
requires 'Try::Tiny';
requires 'parent';

requires 'Devel::StackTrace'; # Middleware::StackTrace
requires 'Devel::StackTrace::AsHTML'; # Middleware::StackTrace

requires 'Filesys::Notify::Simple'; # plackup -r

# TODO: they can go away once we create Plack-Middlewares dist
# Middleware::Static and App::File
requires 'Path::Class', 'MIME::Types';

# Middleware::Deflater
requires 'IO::Compress::Gzip','IO::Compress::Deflate';

build_requires 'Test::More', 0.88;
build_requires 'Test::TCP', 0.11;
test_requires 'Test::Requires';
test_requires 'Test::Exception';
test_requires 'Test::Base';

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t';
author_tests 'xt';

install_share 'share';
install_script 'scripts/plackup';

use_test_base;
auto_include;
auto_install;
auto_set_repository;
WriteAll;
