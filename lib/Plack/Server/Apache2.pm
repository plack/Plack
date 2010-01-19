package Plack::Server::Apache2;
use strict;
use parent qw(Plack::Handler::Apache2);
use Carp;

sub new {
    my $class = shift;
    Carp::carp "Use of $class is deprecated. Use Plack::Handler::Apache2 or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::Apache2 - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::Apache2>.

=cut
