package Plack::Middleware;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Carp ();

__PACKAGE__->mk_accessors(qw/app/);

sub import {
    my($class, @subclasses) = @_;

    for my $sub (@subclasses) {
        my $subclass = $sub =~ s/^\+// ? $sub : "Plack::Middleware::$sub";
        eval "use $subclass";
        die $@ if $@;
    }
}

sub wrap {
    my($class, @args) = @_;
    my $app = pop @args;
    $class->new({ app => $app, @args })->to_app;
}

sub to_app {
    my $self = shift;
    return sub { $self->call(@_) };
}

sub enable {
    Carp::croak "enable Plack::Middleware should be called inside Plack::Builder's builder {} block";
}

1;

__END__

=head1 NAME

Plack::Middleware - Base class for easy-to-use PSGI middleware

=head1 SYNOPSIS

  package Plack::Middleware::Foo;
  use base qw( Plack::Middleware );

  sub call {
      my($self, $env) = @_;
      # Do something with $env

      # $self->app is the original app
      my $res = $self->app->($env);

      # Do something with $res
      return $res;
  }

  # then in app.psgi
  use Plack::Builder;
  use Plack::Middleware qw( Foo Bar );

  my $app = sub { ... } # as usual

  builder {
      enable Plack::Middleware::Foo;
      enable Plack::Middleware::Bar %options;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware is an utility base class to write PSGI
middleware. All you have to do is to inherit from Plack::Middleware
and then implement the callback C<call> method (or C<to_app> method
that would return the PSGI code reference) to do the actual work. You
can use C<< $self->app >> to call the original (wrapped) application.

See L<Plack::Builder> how to actually enable them in your I<.psgi>
application file using the DSL. If you do not like our builder DSL,
you can also use C<wrap> method to wrap your application with a
middleware:

  use Plack::Middleware::Foo;

  my $app = sub { ... };
  Plack::Middleware::Foo->wrap(@options, $app);

=head1 SEE ALSO

L<Plack> L<Plack::Builder>

=cut
