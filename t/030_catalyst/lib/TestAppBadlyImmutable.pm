package TestAppBadlyImmutable;
use Catalyst qw/+TestPluginWithConstructor/;
use Test::More;

__PACKAGE__->setup;

ok !__PACKAGE__->meta->is_immutable, 'Am not already immutable';
__PACKAGE__->meta->make_immutable( inline_constructor => 0 );
ok __PACKAGE__->meta->is_immutable, 'Am now immutable';

1;

