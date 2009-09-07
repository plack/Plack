use strict;
use warnings;

use FindBin qw/$Bin/;
use lib "$Bin/../lib";

use Test::More tests => 2;

use TestApp;
use TestApp::Role;

is $TestApp::Role::SETUP_FINALIZE, 1, 'TestApp->setup_finalize modifier run once';
is $TestApp::Role::SETUP_DISPATCHER, 1, 'TestApp->setup_dispacter modifier run once';

