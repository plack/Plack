package Plack::Server::Standalone;
use strict;
use parent qw(Plack::Handler::Standalone);

sub new {
    my $class = shift;
    warn "Use of $class is deprecated. Use Plack::Handler::Standalone or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::Standalone - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::Standalone>.

=cut
