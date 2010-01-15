package Plack::Server::Apache1;
use strict;
use parent qw(Plack::Handler::Apache1);

sub new {
    my $class = shift;
    warn "Use of $class is deprecated. Use Plack::Handler::Apache1 or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::Apache1 - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::Apache1>.

=cut
