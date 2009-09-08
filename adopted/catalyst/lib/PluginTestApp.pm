package PluginTestApp;
use Test::More;

use Catalyst qw(
        Test::Plugin
        +TestApp::Plugin::FullyQualified
        );

sub compile_time_plugins : Local {
    my ( $self, $c ) = @_;

    isa_ok $c, 'Catalyst::Plugin::Test::Plugin';
    isa_ok $c, 'TestApp::Plugin::FullyQualified';

    can_ok $c, 'registered_plugins';
    $c->_test_plugins;

    $c->res->body("ok");
}

sub run_time_plugins : Local {
    my ( $self, $c ) = @_;

    $c->_test_plugins;
    my $faux_plugin = 'Faux::Plugin';

# Trick perl into thinking the plugin is already loaded
    $INC{'Faux/Plugin.pm'} = 1;

    __PACKAGE__->plugin( faux => $faux_plugin );

    isa_ok $c, 'Catalyst::Plugin::Test::Plugin';
    isa_ok $c, 'TestApp::Plugin::FullyQualified';
    ok !$c->isa($faux_plugin),
    '... and it should not inherit from the instant plugin';
    can_ok $c, 'faux';
    is $c->faux->count, 1, '... and it should behave correctly';
    is_deeply [ $c->registered_plugins ],
    [
        qw/Catalyst::Plugin::Test::Plugin
        Faux::Plugin
        TestApp::Plugin::FullyQualified/
        ],
    'registered_plugins() should report all plugins';
    ok $c->registered_plugins('Faux::Plugin'),
    '... and even the specific instant plugin';

    $c->res->body("ok");
}

sub _test_plugins {
    my $c = shift;
    is_deeply [ $c->registered_plugins ],
    [
        qw/Catalyst::Plugin::Test::Plugin
        TestApp::Plugin::FullyQualified/
        ],
    '... and it should report the correct plugins';
    ok $c->registered_plugins('Catalyst::Plugin::Test::Plugin'),
    '... or if we have a particular plugin';
    ok $c->registered_plugins('Test::Plugin'),
    '... even if it is not fully qualified';
    ok !$c->registered_plugins('No::Such::Plugin'),
    '... and it should return false if the plugin does not exist';
}

__PACKAGE__->setup;
