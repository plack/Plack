package Plack::Middleware;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use overload '&{}' => sub {
    my $self = $_[0];
    return sub { $self->call(@_) };
  },
  fallback => 1;

__PACKAGE__->mk_accessors(qw/code/);

1;
