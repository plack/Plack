package Plack::Server::Standalone::Prefork;
use strict;
use parent qw(HTTP::Server::PSGI); # because Standalone is a wrapper
use Carp;

sub new {
    my $class = shift;
    Carp::carp "Use of $class is deprecated. Use Plack::Handler::Standalone or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::Standalone::Prefork - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::Standalone>.

=cut
