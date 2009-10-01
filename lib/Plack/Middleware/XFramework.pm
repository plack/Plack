package Plack::Middleware::XFramework;
use strict;
use warnings;
use base qw/Plack::Middleware/;
__PACKAGE__->mk_accessors(qw/framework/);

use Plack::Util;

sub call {
    my $self = shift;

    my $res = $self->app->( @_ );
    if ($self->framework) {
        Plack::Util::header_set $res->[1], 'X-Framework' => $self->framework;
    }
    $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::XFramework - Sample middleware to add X-Framework

=head1 SYNOPSIS

  enable Plack::Middleware::XFramework framework => "Catalyst";

=head1 DESCRIPTION

This middleware adds C<X-Framework> header to the HTTP response.

=head1 CONFIGURATION

=over 4

=item framework

Sets the string value of C<X-Framework> header. If not set, the header is not set to the response.

=back

=head1 SEE ALSO

L<Plack::Middleware>

=cut

