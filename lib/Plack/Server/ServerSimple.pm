package Plack::Server::ServerSimple;
use strict;
our $VERSION = '0.9985';
$VERSION = eval $VERSION;

use parent qw(Plack::Handler::HTTP::Server::Simple);
use Carp;

sub new {
    my $class = shift;
    Carp::carp "$class is deprecated. Use -s HTTP::Server::Simple";
    $class->SUPER::new(@_);
}

1;

__END__

=head1 NAME

Plack::Server::ServerSimple - DEPRECATED

=head1 DESCRIPTION

B<DEPRECATED>. Use Plack::Handler::HTTP::Server::Simple.

=cut
