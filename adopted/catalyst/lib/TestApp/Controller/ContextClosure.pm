package TestApp::Controller::ContextClosure;

use Moose;

BEGIN {
    extends 'Catalyst::Controller';
    with 'Catalyst::Component::ContextClosure';
}

sub normal_closure : Local {
    my ($self, $ctx) = @_;
    $ctx->stash(closure => sub {
        $ctx->response->body('from normal closure');
    });
    $ctx->response->body('stashed normal closure');
}

sub context_closure : Local {
    my ($self, $ctx) = @_;
    $ctx->stash(closure => $self->make_context_closure(sub {
        my ($ctx) = @_;
        $ctx->response->body('from context closure');
    }, $ctx));
    $ctx->response->body('stashed context closure');
}

__PACKAGE__->meta->make_immutable;

1;
