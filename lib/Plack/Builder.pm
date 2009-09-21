package Plack::Builder;
use strict;
use base qw( Exporter );

our @EXPORT = qw( builder );

sub builder(&) {
    my $block = shift;

    no warnings 'redefine';
    my @wrappers;
    local *Plack::Middleware::enable = sub {
        my($class, @args) = @_;
        push @wrappers, sub { $class->wrap(@args, $_[0]) };
    };

    my $app = $block->();

    for my $mw (reverse @wrappers) {
        $app = $mw->($app);
    }

    return $app;
}

1;

__END__

=head1 NAME

Plack::Builder - DSL to enable Plack::Middleware in .psgi files

=head1 SYNOPSIS

  use Plack::Builder
  use Plack::Middleware qw( Foo Bar Baz );

  my $app = sub { ... };

  builder {
     enable Plack::Middleware::Foo;
     enable Plack::Middleware::Bar opt => "val";
     enable Plack::Middleware::Baz;
     $app;
  };

=head1 DESCRIPTION

Plack::Builder gives you a quick DSL to wrap your application with
Plack::Middleware subclasses. The middleware you're trying to use
should use L<Plack::Middleware> as a base class to use this DSL,
inspired by Rack::Builder.

Whenever you call C<enable> on any middleware, the middleware app is
pushed to the stack inside the builder, and then reversed when it
actually creates a wrapped application handler, so:

  builder {
     enable Plack::Middleware::Foo;
     enable Plack::Middleware::Bar opt => "val";
     $app;
  };

is syntactically equal to:

  Plack::Middleware::Foo->wrap(
      Plack::Middleware::Bar->wrap(opt => "val", $app)
  );

=head1 SEE ALSO

L<Plack::Middleware>

=cut



