package Plack::Server::Standalone::Prefork;
use strict;
use parent qw(HTTP::Server::PSGI); # because Standalone is a wrapper
use Carp;

sub new {
    my $class = shift;
    Carp::carp "Use of $class is deprecated. Use Starman or Starlet for preforking servers.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::Standalone::Prefork - DEPRECATED use Starman or Starlet instead

=head1 DESCRIPTION

B<This module is deprecated>.

=head1 SEE ALSO

L<HTTP::Server::PSGI> L<Starman> L<Starlet>

=cut
