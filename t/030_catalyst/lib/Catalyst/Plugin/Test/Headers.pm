package Catalyst::Plugin::Test::Headers;

use strict;
use MRO::Compat;

sub prepare {
    my $class = shift;

    my $c = $class->next::method(@_);

    $c->response->header( 'X-Catalyst-Engine' => $c->engine );
    $c->response->header( 'X-Catalyst-Debug' => $c->debug ? 1 : 0 );
    
    {
        my $components = join( ', ', sort keys %{ $c->components } );
        $c->response->header( 'X-Catalyst-Components' => $components );
    }

    {
        no strict 'refs';
        my $plugins = join ', ', $class->registered_plugins;
        $c->response->header( 'X-Catalyst-Plugins' => $plugins );
    }

    return $c;
}

sub prepare_action {
    my $c = shift;
    $c->next::method(@_);
    $c->res->header( 'X-Catalyst-Action' => $c->req->action );
}

1;
