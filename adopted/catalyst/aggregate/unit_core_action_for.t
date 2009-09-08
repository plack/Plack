#!perl

use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More;

plan tests => 4;

use_ok('TestApp');

is(TestApp->action_for('global_action')->code, TestApp->can('global_action'),
   'action_for on appclass ok');

is(TestApp->controller('Args')->action_for('args')->code,
   TestApp::Controller::Args->can('args'),
   'action_for on controller ok');
   is(TestApp->controller('Args')->action_for('args').'',
      'args/args',
      'action stringifies');
