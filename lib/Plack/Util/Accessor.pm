package Plack::Util::Accessor;
use strict;
use warnings;

sub import {
    shift;
    return unless @_;
    my $package = caller();
    mk_accessors( $package, @_ );
}

sub mk_accessors {
    my $package = shift;
    no strict 'refs';
    foreach my $field ( @_ ) {
        *{ $package . '::' . $field } = sub {
            return $_[0]->{ $field } if scalar( @_ ) == 1;
            return $_[0]->{ $field }  = scalar( @_ ) == 2 ? $_[1] : [ @_[1..$#_] ];
        };
    }
}

1;

__END__

=head1 NAME

Plack::Util::Accessor - Accessor generation utility for Plack

=head1 DESCRIPTION

This module is just a simple accessor generator for Plack to replace
the Class::Accessor::Fast usage and so our classes don't have to inherit
from their accessor generator.

=head1 SEE ALSO

L<PSGI> L<http://plackperl.org/>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
