use Test::More tests => 6;
use strict;
use warnings;
use lib 't/lib';

# This tests that we actually load the physical
#  copy of Model::Foo::Bar, in the case that Model::Foo
#  defines the Model::Foo::Bar namespace in memory,
#  but does not load the corresponding file.

use_ok 'TestApp';

my $model_foo     = TestApp->model('Foo');

can_ok($model_foo, 'model_foo_method');
can_ok($model_foo, 'bar');

my $model_foo_bar = $model_foo->bar;

can_ok($model_foo_bar, 'model_foo_bar_method_from_foo');
can_ok($model_foo_bar, 'model_foo_bar_method_from_foo_bar');

TestApp->setup;

is($model_foo->model_quux_method, 'chunkybacon', 'Model method getting $self->{quux} from config');

