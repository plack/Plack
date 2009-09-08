package Catalyst::Plugin::Test::Plugin;

use strict;
use warnings;
use MRO::Compat;

use base qw/Catalyst::Controller Class::Data::Inheritable/;

 __PACKAGE__->mk_classdata('ran_setup');

sub setup {
   my $c = shift;
   $c->ran_setup('1');
}

sub prepare {
    my $class = shift;

    my $c = $class->next::method(@_);
    $c->response->header( 'X-Catalyst-Plugin-Setup' => $c->ran_setup );

    return $c;
}

# Note: This is horrible, but Catalyst::Plugin::Server forces the body to
#       be parsed, by calling the $c->req->body method in prepare_action.
#       We need to test this, as this was broken by 5.80. See also
#       t/aggregate/live_engine_request_body.t. Better ways to test this
#       appreciated if you have suggestions :)
{
    my $have_req_body = 0;
    sub prepare_action {
        my $c = shift;
        $have_req_body++ if $c->req->body;
        $c->next::method(@_);
    }
    sub have_req_body_in_prepare_action : Local {
        my ($self, $c) = @_;
        $c->res->body($have_req_body);
    }
}

sub end : Private {
    my ($self,$c) = @_;
}

1;
