package Plack::Server::CGI;
use strict;
use parent qw(Plack::Handler::CGI);
use Carp;

sub new {
    my $class = shift;
    Carp::carp "Use of $class is deprecated. Use Plack::Handler::CGI or Plack::Loader to upgrade.";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::CGI - DEPRECATED

=head1 DESCRIPTION

B<This module is deprecated>. See L<Plack::Handler::CGI>.

=cut
