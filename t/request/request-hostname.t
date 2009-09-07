use strict;
use warnings;
use Test::More;

use t::Utils;

plan tests => 2;

# get hostname by REMOTE_HOST
is _get(REMOTE_HOST => 'mudage.example.com'), "mudage.example.com";

# get hostname by REMOTE_ADDR
ok _get(REMOTE_HOST => '', REMOTE_ADDR => '127.0.0.1');

sub _get { req(env => {@_})->hostname }

