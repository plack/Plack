package Plack::Middleware;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;

__PACKAGE__->mk_accessors(qw/app/);

sub import {
    my($class, @subclasses) = @_;

    for my $sub (@subclasses) {
        eval "use Plack::Middleware::$sub";
        die $@ if $@;
    }
}

# DSL!
sub enable {
    my($class, @args) = @_;
    my $app = pop @args;
    $class->new({ @args, app => $app })->app_handler;
}

1;

__END__

=head1 NAME

Plack::Middleware - Base class for easy-to-use PSGI middleware

=head1 SYNOPSIS

  package Plack::Middleware::Foo;
  use base qw( Plack::Middleware );

  sub app_handler {
      my $self = shift;

      return sub {
          my $env = shift;

          # Do something with $env

          # $self->app is the original app
          my $res = $self->app->($env, @_);

          # Do something with $res

          return $res;
      }
  }

  # then in app.psgi

  my $app = sub { ... }

  enable Plack::Middleware::Foo
  enable Plack::Middleware::Bar %options, $app;

=head1 DESCRIPTION

Plack::Middleware is an utility base class to write PSGI middleware.

=head1 SEE ALSO

L<Plack>

=cut
