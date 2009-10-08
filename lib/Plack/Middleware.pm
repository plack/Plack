package Plack::Middleware;
use strict;
use warnings;
use base qw/Class::Accessor::Fast/;
use Carp ();

__PACKAGE__->mk_accessors(qw/app/);

sub import {
    my $class = shift;
    if (@_) {
        Carp::carp("use Plack::Middleware qw(Foo) is deprecated. See perldoc Plack::Builder");
    }
}

sub wrap {
    my($class, $app, @args) = @_;
    $class->new({ app => $app, @args })->to_app;
}

sub to_app {
    my $self = shift;
    return sub { $self->call(@_) };
}

sub enable {
    Carp::croak("enable Plack::Middleware::Foo is deprecated. See perldoc Plack::Builder");
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

  my $app = sub { ... } # as usual

  builder {
      add "Plack::Middleware::Foo";
      add "Plack::Middleware::Bar", %options;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware is an utility base class to write PSGI
middleware. All you have to do is to inherit from Plack::Middleware
and then implement the callback C<call> method (or C<to_app> method
that would return the PSGI code reference) to do the actual work. You
can use C<< $self->app >> to call the original (wrapped) application.

See L<Plack::Builder> how to actually add "them", in your I<.psgi>
application file using the DSL. If you do not like our builder DSL,
you can also use C<wrap> method to wrap your application with a
middleware:

  use Plack::Middleware::Foo;

  my $app = sub { ... };
  $app = Plack::Middleware::Foo->wrap($app, %options);

=head1 SEE ALSO

L<Plack> L<Plack::Builder>

=cut
