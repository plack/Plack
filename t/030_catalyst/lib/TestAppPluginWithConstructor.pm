# See t/plugin_new_method_backcompat.t
package TestAppPluginWithConstructor;
use Test::More;
use Test::Exception;
use Catalyst qw/+TestPluginWithConstructor/;
use Moose;
BEGIN { extends qw/Catalyst Catalyst::Controller/ } # Ewww, FIXME.

sub foo : Local {
    my ($self, $c) = @_;
    $c->res->body('foo');
}

__PACKAGE__->setup;
our $MODIFIER_FIRED = 0;

lives_ok {
    before 'dispatch' => sub { $MODIFIER_FIRED = 1 }
} 'Can apply method modifier';
no Moose;

our $IS_IMMUTABLE_YET = __PACKAGE__->meta->is_immutable;
ok !$IS_IMMUTABLE_YET, 'I am not immutable yet';

1;

