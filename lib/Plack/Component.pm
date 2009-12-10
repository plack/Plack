package Plack::Component;
use strict;
use warnings;
use Carp ();
use Plack::Util;
use overload '&{}' => sub { shift->to_app(@_) }, fallback => 1;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        $self = bless {%{$_[0]}}, $class;
    } else {
        $self = bless {@_}, $class;
    }

    $self;
}

# NOTE:
# this is for back-compat only,
# future modules should use
# Plack::Util::Accessor directly
# or their own favorite accessor
# generator.
# - SL
sub mk_accessors {
    my $self = shift;
    Plack::Util::Accessor::mk_accessors( ref( $self ) || $self, @_ )
}

sub prepare_app { return }

sub to_app {
    my $self = shift;
    $self->prepare_app;
    return sub { $self->call(@_) };
}

1;

__END__

=head1 NAME

Plack::Component - Base class for PSGI endpoints

=head1 SYNOPSIS

  package Plack::App::Foo;
  use parent qw( Plack::Component );

  sub call {
      my($self, $env) = @_;
      # Do something with $env

      my $res = ...; # create a response ...

      # return the response
      return $res;
  }

=head1 DESCRIPTION

Plack::Component is the base class shared between Plack::Middleware
and Plack::App::* modules. If you are writing middleware, you should
inherit from L<Plack::Middleware>, but if you are writing a
Plack::App::* you should inherit from this directly.

=head1 REQUIRED METHOD

=over 4

=item call ($env)

You are expected to implement a C<call> method in your component. This is
where all the work gets done. It receives the PSGI C<$env> hash-ref as an
argument and is expected to return a proper PSGI response value.

=back

=head1 METHODS

=over 4

=item new (%opts | \%opts)

The constructor accepts either a hash or a hash-ref and uses that to
create the instance with. It will call no other methods and simply return
the instance that is created.

=item prepare_app

This method is called by C<to_app> and is meant as a hook to be used to
prepare your component before it is packaged as a PSGI C<$app>.

=item to_app

This is the method used in several parts of the Plack infrastructure to
convert your component into a PSGI C<$app>. You should not ever need to
override this method, it is recommended to use C<prepare_app> and C<call>
instead.

=back

=head1 BACKWARDS COMPATIBILITY

The L<Plack::Middleware> module used to inherit from L<Class::Accessor::Fast>,
which has been removed in favor of the L<Plack::Util::Accessor> module. When
developing new components it is recommended to use L<Plack::Util::Accessor>
like so:

  use Plack::Util::Accessor qw( foo bar baz );

However, in order to keep backwards compatibility this module provides a
C<mk_accessors> method similar to L<Class::Accessor::Fast>. New code should
not use this and use L<Plack::Util::Accessor> instead.

=head1 SEE ALSO

L<Plack> L<Plack::Builder> L<Plack::Middleware>

=cut
