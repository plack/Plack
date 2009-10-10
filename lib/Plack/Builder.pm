package Plack::Builder;
use strict;
use base qw( Exporter );
our @EXPORT = qw( builder add dispatch );

use Carp ();
use Plack::App::URLMap;

sub new {
    my $class = shift;
    bless { middlewares => [ ] }, $class;
}

sub add_middleware {
    my($self, $mw, @args) = @_;

    if (ref $mw ne 'CODE') {
        my $mw_class = $mw;
        eval "use $mw_class";
        die $@ if $@;
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    push @{$self->{middlewares}}, $mw;
}

# do you want remove_middleware() etc.?

sub to_app {
    my($self, $app) = @_;

    for my $mw (reverse @{$self->{middlewares}}) {
        $app = $mw->($app);
    }

    $app;
}

# DSL goes here
our $_add = our $_dispatch = sub {
    Carp::croak("add/dispatch should be called inside builder {} block");
};

sub add      { $_add->(@_) }
sub dispatch { $_dispatch->(@_) }

sub builder(&) {
    my $block = shift;

    my $self = __PACKAGE__->new;

    my $urlmap = Plack::App::URLMap->new;
    local $_dispatch = sub {
        $urlmap->map(@_);
        $urlmap;
    };

    local $_add = sub {
        $self->add_middleware(@_);
    };

    my $app = $block->();
    $self->to_app($app);
}

1;

__END__

=head1 NAME

Plack::Builder - OO and DSL to enable Plack Middlewares

=head1 SYNOPSIS

  # in .psgi
  use Plack::Builder;

  my $app = sub { ... };

  builder {
      add "Plack::Middleware::Foo";
      add "Plack::Middleware::Bar", opt => "val";
      add "Plack::Middleware::Baz";
      $app;
  };

  # use URLMap

  builder {
      dispatch "/foo" => builder {
          add "Plack::Middleware::Foo";
          $app;
      };

      dispatch "/bar" => $app2;
      dispatch "http://example.com/" => builder { $app3 };
  };

=head1 DESCRIPTION

Plack::Builder gives you a quick domain specific language (DSL) to
wrap your application with Plack::Middleware subclasses. The
middleware you're trying to use should use L<Plack::Middleware> as a
base class to use this DSL, inspired by Rack::Builder.

Whenever you call C<add> on any middleware, the middleware app is
pushed to the stack inside the builder, and then reversed when it
actually creates a wrapped application handler, so:

  builder {
      add "Plack::Middleware::Foo";
      add "Plack::Middleware::Bar", opt => "val";
      $app;
  };

is syntactically equal to:

  $app = Plack::Middleware::Bar->wrap($app, opt => "val");
  $app = Plack::Middleware::Foo->wrap($app);

In other words, you're suposed to C<add> middleware from outer to inner.

=head1 URLMap support

Plack::Builder has a native support for L<Plack::App::URLMap> with C<dispatch> method.

  use Plack::Builder;
  my $app = builder {
      dispatch "/foo" => $app1;
      dispatch "/bar" => builder {
          add "Plack::Middleware::Foo";
          $app2;
      };
  };

See L<Plack::App::URLMap>'s C<map> method to see what they mean. With
builder you can't use C<map> as a DSL, for the obvious reason :)

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::App::URLMap>

=cut



