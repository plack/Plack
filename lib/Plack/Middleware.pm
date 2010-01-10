package Plack::Middleware;
use strict;
use warnings;
use Carp ();
use parent qw(Plack::Component);
use Plack::Util;
use Plack::Util::Accessor qw( app );

sub import {
    my $class = shift;
    if (@_) {
        Carp::carp("use Plack::Middleware qw(Foo) is deprecated. See perldoc Plack::Builder");
    }
}

sub wrap {
    my($self, $app, @args) = @_;
    if (ref $self) {
        $self->{app} = $app;
    } else {
        $self = $self->new({ app => $app, @args });
    }
    return $self->to_app;
}

sub response_cb {
    my($self, $res, $cb) = @_;

    my $body_filter = sub {
        my($cb, $res) = @_;
        my $filter_cb = $cb->($res);
        # If response_cb returns a callback, treat it as a $body filter
        if (defined $filter_cb && ref $filter_cb eq 'CODE') {
            Plack::Util::header_remove($res->[1], 'Content-Length');
            if (defined $res->[2]) {
                if (ref $res->[2] eq 'ARRAY') {
                    for my $line (@{$res->[2]}) {
                        $line = $filter_cb->($line);
                    }
                    # Send EOF.
                    push @{ $res->[2] }, $filter_cb->( undef );
                } else {
                    my $body    = $res->[2];
                    my $getline = sub { $body->getline };
                    $res->[2] = Plack::Util::inline_object
                        getline => sub { $filter_cb->($getline->()) },
                        close => sub { $body->close };
                }
            } else {
                return $filter_cb;
            }
        }
    };

    if (ref $res eq 'ARRAY') {
        $body_filter->($cb, $res);
        return $res;
    } elsif (ref $res eq 'CODE') {
        return sub {
            my $respond = shift;
            $res->(sub {
                my $res = shift;
                my $filter_cb = $body_filter->($cb, $res);
                if ($filter_cb) {
                    my $writer = $respond->($res);
                    if ($writer) {
                        return Plack::Util::inline_object
                            write => sub { $writer->write($filter_cb->(@_)) },
                            close => sub { $writer->write($filter_cb->(undef)); $writer->close };
                    }
                } else {
                    return $respond->($res);
                }
            });
        };
    }

    return $res;
}

1;

__END__

=head1 NAME

Plack::Middleware - Base class for easy-to-use PSGI middleware

=head1 SYNOPSIS

  package Plack::Middleware::Foo;
  use parent qw( Plack::Middleware );

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
      enable "Plack::Middleware::Foo";
      enable "Plack::Middleware::Bar", %options;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware is an utility base class to write PSGI
middleware. All you have to do is to inherit from Plack::Middleware
and then implement the callback C<call> method (or C<to_app> method
that would return the PSGI code reference) to do the actual work. You
can use C<< $self->app >> to call the original (wrapped) application.

See L<Plack::Builder> how to actually enable middlewares in your
I<.psgi> application file using the DSL. If you do not like our
builder DSL, you can also use C<wrap> method to wrap your application
with a middleware:

  use Plack::Middleware::Foo;

  my $app = sub { ... };
  $app = Plack::Middleware::Foo->wrap($app, %options);
  $app = Plack::Middleware::Bar->wrap($app, %options);

=head1 SEE ALSO

L<Plack> L<Plack::Builder>

=cut
