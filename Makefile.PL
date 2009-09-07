use inc::Module::Install;
name 'Plack';
all_from 'lib/Plack.pm';

# requires '';

tests 't/*.t';
author_tests 'xt';

build_requires 'Test::More';
use_test_base;
auto_include;
WriteAll;
