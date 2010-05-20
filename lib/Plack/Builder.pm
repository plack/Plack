package Plack::Builder;
use strict;
use parent qw( Exporter );
our @EXPORT = qw( builder add enable enable_if mount );

use Carp ();
use Plack::App::URLMap;
use Plack::Middleware::Conditional; # TODO delayed load?

sub new {
    my $class = shift;
    bless { middlewares => [ ] }, $class;
}

sub add_middleware {
    my($self, $mw, @args) = @_;

    if (ref $mw ne 'CODE') {
        my $mw_class = Plack::Util::load_class($mw, 'Plack::Middleware');
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    push @{$self->{middlewares}}, $mw;
}

sub add_middleware_if {
    my($self, $cond, $mw, @args) = @_;

    if (ref $mw ne 'CODE') {
        my $mw_class = Plack::Util::load_class($mw, 'Plack::Middleware');
        $mw = sub { $mw_class->wrap($_[0], @args) };
    }

    push @{$self->{middlewares}}, sub {
        Plack::Middleware::Conditional->wrap($_[0], condition => $cond, builder => $mw);
    };
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
our $_add = our $_add_if = our $_mount = sub {
    Carp::croak("enable/mount should be called inside builder {} block");
};

sub add      { Carp::carp("add is deprecated. Use 'enable'"); $_add->(@_) }
sub enable         { $_add->(@_) }
sub enable_if(&$@) { $_add_if->(@_) }
sub mount          { $_mount->(@_) }

sub builder(&) {
    my $block = shift;

    my $self = __PACKAGE__->new;

    my $mount_is_called;
    my $urlmap = Plack::App::URLMap->new;
    local $_mount = sub {
        $mount_is_called++;
        $urlmap->map(@_);
        $urlmap;
    };
    local $_add = sub {
        $self->add_middleware(@_);
    };
    local $_add_if = sub {
        $self->add_middleware_if(@_);
    };

    my $app = $block->();
    if ($mount_is_called && $app ne $urlmap) {
        Carp::carp("You used mount() in builder block but the last line (app) isn't using mount().\n" .
                       "This causes all mount() mappings ignored. See perldoc Plack::Builder for details.");
    }

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
      enable "Plack::Middleware::Foo";
      enable "Plack::Middleware::Bar", opt => "val";
      enable "Plack::Middleware::Baz";
      enable sub {
          my $app = shift;
          sub {
              my $env = shift;
              $app->($env);
          };
      };
      $app;
  };

  # use URLMap

  builder {
      mount "/foo" => builder {
          enable "Plack::Middleware::Foo";
          $app;
      };

      mount "/bar" => $app2;
      mount "http://example.com/" => builder { $app3 };
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
      enable "Plack::Middleware::Foo";
      enable "Plack::Middleware::Bar", opt => "val";
      $app;
  };

is syntactically equal to:

  $app = Plack::Middleware::Bar->wrap($app, opt => "val");
  $app = Plack::Middleware::Foo->wrap($app);

In other words, you're supposed to C<add> middleware from outer to inner.

Additionally, you can call C<enable> with a coderef, which would take
C<$app> and returns a another psgi-app which consumes C<$env> in runtime.  So:

  my $mw = sub {
      my $app = shift;
      sub { my $env = shift; $app->($env) };
  };

  builder {
      enable $mw;
      $app;
  };

is syntactically equal to:

  $app = $mw->($app);

=head1 URLMap support

Plack::Builder has a native support for L<Plack::App::URLMap> with C<mount> method.

  use Plack::Builder;
  my $app = builder {
      mount "/foo" => $app1;
      mount "/bar" => builder {
          enable "Plack::Middleware::Foo";
          $app2;
      };
  };

See L<Plack::App::URLMap>'s C<map> method to see what they mean. With
builder you can't use C<map> as a DSL, for the obvious reason :)

B<Note>: Once you use C<mount> in your builder code, you have to use
C<mount> for all the paths, including the root path (C</>). You can't
have the default app in the last line of C<builder> like:

  builder {
      mount "/foo" => sub { ... };
      sub {
          my $env = shift; # THIS DOESN'T WORK
      };
  };

You'll get warnings saying that your mount configuration will be
ignored.  Instead you should use C<< mount "/" => ... >> in the last
line to set the default fallback app.

=head1 CONDITIONAL MIDDLEWARE SUPPORT

You can use C<enable_if> to conditionally enable middleware based on
the runtime environment. See L<Plack::Middleware::Conditional> for
details.

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::App::URLMap> L<Plack::Middleware::Conditional>

=cut



