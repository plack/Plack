package Plack::Middleware::XFramework;
use strict;
use warnings;
use parent qw/Plack::Middleware/;

use Plack::Util;
use Plack::Util::Accessor qw( framework );

sub call {
    my $self = shift;

    my $res = $self->app->( @_ );
    $self->response_cb($res, sub {
        my $res = shift;
        if ($self->framework) {
            Plack::Util::header_set $res->[1], 'X-Framework' => $self->framework;
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::XFramework - Sample middleware to add X-Framework

=head1 SYNOPSIS

  enable "Plack::Middleware::XFramework", framework => "Catalyst";

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

