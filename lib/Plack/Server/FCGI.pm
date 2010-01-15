package Plack::Server::FCGI;
use strict;
use parent qw(Plack::Handler::FCGI);
use Carp;

sub new {
    my $class = shift;
    Carp::carp "Use of $class is deprecated. Use Plack::Handler::FCGI or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::FCGI - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::FCGI>.

=cut
