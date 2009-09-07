package TestApp::Controller::Keyword;

use strict;
use base 'Catalyst::Controller';

#
# Due to 'actions' being used as an attribute up to cat 5.80003 using this name
# for an action causes a weird error, as this would be called during BUILD time
# of the Catalyst::Controller class
#

sub actions : Local {
    my ( $self, $c ) = @_;
    die("Call to controller action method without context! Probably naming clash") unless $c;
    $c->res->output("Test case for using 'actions' as a catalyst action name\n");
}

1;
