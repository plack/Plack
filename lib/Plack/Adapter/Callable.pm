package Plack::Adapter::Callable;
use strict;
use warnings;
use Carp ();

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;
    return sub { $self->{app}->call(@_) };
}

sub call { Carp::croak "NOT IMPLEMENTED 'call' METHOD" }

1;

__END__

=head1 SYNOPSIS

  package Hokke;
  use strict;
  use warnings;
  use base 'Plack::Adapter::Callable';
  use Data::Dumper;
  sub call {
      [ 200, [ 'Content-Type' => 'text/plain' ], [ Dumper(\@_) ] ];
  }
  1;

run plackup

  $ plackup Hokke

=head1 AUTHOR

yappo

=cut
