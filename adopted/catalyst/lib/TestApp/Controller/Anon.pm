package Anon::Trait;
use Moose::Role -traits => 'MethodAttributes'; # Needed for role composition to work correctly with anon classes.

after test => sub {
    my ($self, $c) = @_;
    $c->res->header('X-Anon-Trait-Applied', 1);
};

no Moose::Role;

package TestApp::Controller::Anon;
use Moose;
use Moose::Util qw/find_meta/;
use namespace::clean -except => 'meta';
BEGIN { extends 'Catalyst::Controller' };

sub COMPONENT { # Don't do this yourself, use CatalystX::Component::Traits!
    my ($class, $app, $args) = @_;

    my $meta = $class->meta->create_anon_class(
            superclasses => [ $class->meta->name ],
            roles        => ['Anon::Trait'],
            cache        => 1,
    );
    # Special move as the methodattributes trait has changed our metaclass..
    $meta = find_meta($meta->name);

    $meta->add_method('meta' => sub { $meta });
    $class = $meta->name;
    $class->new($app, $args);
}

sub test : Local ActionClass('+TestApp::Action::TestMyAction') {
    my ($self, $c) = @_;
    $c->res->header('X-Component-Name-Controller', $self->catalyst_component_name);
    $c->res->body('It works');
}

__PACKAGE__->meta->make_immutable;

