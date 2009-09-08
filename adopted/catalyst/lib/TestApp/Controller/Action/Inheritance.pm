package TestApp::Controller::Action::Inheritance;

use strict;
use base 'TestApp::Controller::Action';

sub auto : Private {
    my ( $self, $c ) = @_;
    return 1;
}

sub begin : Private {
    my ( $self, $c ) = @_;
    $self->SUPER::begin($c);
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub end : Private {
    my ( $self, $c ) = @_;
}

package TestApp::Controller::Action::Inheritance::A;

use strict;
use base 'TestApp::Controller::Action';

sub auto : Private {
    my ( $self, $c ) = @_;
    return 1;
}

sub begin : Private {
    my ( $self, $c ) = @_;
    $self->SUPER::begin($c);
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub end : Private {
    my ( $self, $c ) = @_;
}

package TestApp::Controller::Action::Inheritance::A::B;

use strict;
use base 'TestApp::Controller::Action';

sub auto : Private {
    my ( $self, $c ) = @_;
    return 1;
}

sub begin : Private {
    my ( $self, $c ) = @_;
    $self->SUPER::begin($c);
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward('TestApp::View::Dump::Request');
}

sub end : Private {
    my ( $self, $c ) = @_;
}

package TestApp::Controller::Action::Inheritance::B;

use strict;
use base 'TestApp::Controller::Action';

# check configuration for an inherited action
__PACKAGE__->config(
    action => {
        begin => {}
    }
);

1;

