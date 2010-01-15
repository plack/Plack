package Plack::Server::Standalone;
use strict;
use parent qw(Plack::Handler::Standalone);
use Carp;

sub new {
    my $class = shift;
    Carp::carp "Use of $class is deprecated. Use Plack::Handler::Standalone or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::Standalone - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::Standalone>.

=cut
