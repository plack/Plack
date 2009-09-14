package TestApp::View::Dump;

use strict;
use base 'Catalyst::View';

use Data::Dumper ();
use Scalar::Util qw(blessed weaken);

sub dump {
    my ( $self, $reference ) = @_;

    return unless $reference;

    my $dumper = Data::Dumper->new( [$reference] );
    $dumper->Indent(1);
    $dumper->Purity(1);
    $dumper->Useqq(0);
    $dumper->Deepcopy(1);
    $dumper->Quotekeys(0);
    $dumper->Terse(1);

    return $dumper->Dump;
}

sub process {
    my ( $self, $c, $reference, $no_strict ) = @_;

    # Force processing of on-demand data
    $c->prepare_body;

    # Remove body from reference if needed
    $reference->{__body_type} = blessed $reference->body
        if (blessed $reference->{_body});
    my $body = delete $reference->{_body};

    # Remove context from reference if needed
    my $context = delete $reference->{_context};

    if ( my $output =
        $self->dump( $reference ) )
    {

        if ($no_strict) {
            $output = "do { no strict 'refs'; $output }";
        }

        $c->res->headers->content_type('text/plain');
        $c->res->output($output);

        if ($context) {
            # Repair context
            $reference->{_context} = $context;
            weaken( $reference->{_context} );
        }

        if ($body) {
            # Repair body
            delete $reference->{__body_type};
            $reference->{_body} = $body;
        }

        return 1;
    }

    return 0;
}

1;
