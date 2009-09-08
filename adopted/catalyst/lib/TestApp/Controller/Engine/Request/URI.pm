package TestApp::Controller::Engine::Request::URI;

use strict;
use base 'Catalyst::Controller';

sub default : Private {
    my ( $self, $c ) = @_;
    
    $c->forward('TestApp::View::Dump::Request');
}

sub change_path : Local {
    my ( $self, $c ) = @_;
    
    # change the path
    $c->req->path( '/my/app/lives/here' );
    
    $c->forward('TestApp::View::Dump::Request');
}

sub change_base : Local {
    my ( $self, $c ) = @_;
    
    # change the base and uri paths
    $c->req->base->path( '/new/location' );
    $c->req->uri->path( '/new/location/engine/request/uri/change_base' );
    
    $c->forward('TestApp::View::Dump::Request');
}

sub uri_with : Local {
    my ( $self, $c ) = @_;

    # change the current uri
    my $uri   = $c->req->uri_with( { b => 1, c => undef } );
    my %query = $uri->query_form;
    
    $c->res->header( 'X-Catalyst-Param-a' => $query{ a } );
    $c->res->header( 'X-Catalyst-Param-b' => $query{ b } );
    $c->res->header( 'X-Catalyst-Param-c' => exists($query{ c }) ? $query{ c } : '--notexists--' );
    $c->res->header( 'X-Catalyst-query' => $uri->query);
    
    $c->forward('TestApp::View::Dump::Request');
}

sub uri_with_object : Local {
    my ( $self, $c ) = @_;

    my $uri   = $c->req->uri_with( { a => $c->req->base } );
    my %query = $uri->query_form;
    
    $c->res->header( 'X-Catalyst-Param-a' => $query{ a } );
    
    $c->forward('TestApp::View::Dump::Request');
}

sub uri_with_utf8 : Local {
    my ( $self, $c ) = @_;

    # change the current uri
    my $uri = $c->req->uri_with( { unicode => "\x{2620}" } );
    
    $c->res->header( 'X-Catalyst-uri-with' => "$uri" );
    
    $c->forward('TestApp::View::Dump::Request');
}

sub uri_with_undef : Local {
    my ( $self, $c ) = @_;

    my $warnings = 0;
    local $SIG{__WARN__} = sub { $warnings++ };

    # change the current uri
    my $uri = $c->req->uri_with( { foo => undef } );
    
    $c->res->header( 'X-Catalyst-warnings' => $warnings );
    
    $c->forward('TestApp::View::Dump::Request');
}

sub uri_with_undef_only : Local {
    my ( $self, $c ) = @_;

    my $uri = $c->req->uri_with( { a => undef } );
    
    $c->res->header( 'X-Catalyst-uri-with' => "$uri" );
    $c->forward('TestApp::View::Dump::Request');
}

sub uri_with_undef_ignore : Local {
    my ( $self, $c ) = @_;

    my $uri = $c->req->uri_with( { a => 1, b => undef } );
    
    my %query = $uri->query_form;
    $c->res->header( 'X-Catalyst-uri-with' => "$uri" );
    $c->res->header( 'X-Catalyst-Param-a' => $query{ a } );
    $c->res->header( 'X-Catalyst-Param-b' => $query{ b } );
    $c->res->header( 'X-Catalyst-Param-c' => $query{ c } );
    $c->forward('TestApp::View::Dump::Request');
}

1;
