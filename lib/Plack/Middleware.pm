package Plack::Middleware;
use strict;
use warnings;
use Carp ();
use parent qw(Plack::Component);
use Plack::Util;
use Plack::Util::Accessor qw( app );

sub wrap {
    my($self, $app, @args) = @_;
    if (ref $self) {
        $self->{app} = $app;
    } else {
        $self = $self->new({ app => $app, @args });
    }
    return $self->to_app;
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

Plack::Middleware is a utility base class to write PSGI
middleware. All you have to do is to inherit from Plack::Middleware
and then implement the callback C<call> method (or the C<to_app> method
that would return the PSGI code reference) to do the actual work. You
can use C<< $self->app >> to call the original (wrapped) application.

Your middleware object is created at the PSGI application compile time
and is persistent during the web server life cycle (unless it is a
non-persistent environment such as CGI), so you should never set or
cache per-request data like C<$env> in your middleware object. See
also L<Plack::Component/"OBJECT LIFECYCLE">.

See L<Plack::Builder> how to actually enable middleware in your
I<.psgi> application file using the DSL. If you do not like our
builder DSL, you can also use the C<wrap> method to wrap your application
with a middleware:

  use Plack::Middleware::Foo;

  my $app = sub { ... };
  $app = Plack::Middleware::Foo->wrap($app, %options);
  $app = Plack::Middleware::Bar->wrap($app, %options);

=head1 RESPONSE CALLBACK

The typical middleware is written like this:

  package Plack::Middleware::Something;
  use parent qw(Plack::Middleware);

  sub call {
      my($self, $env) = @_;
      # pre-processing $env
      my $res = $self->app->($env);
      # post-processing $res
      return $res;
  }

The tricky thing about post-processing the response is that it could
either be an immediate 3 element array ref, or a code reference that
implements the delayed (streaming) interface.

Dealing with these two types of response in each piece of middleware
is pointless, so you're recommended to use the C<response_cb> wrapper
function in L<Plack::Util> when implementing a post processing
middleware.

  my $res = $app->($env);
  Plack::Util::response_cb($res, sub {
      my $res = shift;
      # do something with $res;
  });

The callback function gets a response as an array reference, and you can
update the reference to implement the post-processing. In the normal
case, this arrayref will have three elements (as described by the PSGI
spec), but will have only two elements when using a C<$writer> as
described below.

  package Plack::Middleware::Always500;
  use parent qw(Plack::Middleware);
  use Plack::Util;

  sub call {
      my($self, $env) = @_;
      my $res  = $self->app->($env);
      Plack::Util::response_cb($res, sub {
          my $res = shift;
          $res->[0] = 500;
          return;
      });
  }

In this example, the callback gets the C<$res> and updates its first
element (status code) to 500. Using C<response_cb> makes sure that
this works with the delayed response too.

You're not required (and not recommended either) to return a new array
reference - they will be simply ignored. You're suggested to
explicitly return, unless you fiddle with the content filter callback
(see below).

Similarly, note that you have to keep the C<$res> reference when you
swap the entire response.

  Plack::Util::response_cb($res, sub {
      my $res = shift;
      $res = [ $new_status, $new_headers, $new_body ]; # THIS DOES NOT WORK
      return;
  });

This does not work, since assigning a new anonymous array to C<$res>
doesn't update the original PSGI response value. You should instead
do:

  Plack::Util::response_cb($res, sub {
      my $res = shift;
      @$res = ($new_status, $new_headers, $new_body); # THIS WORKS
      return;
  });

The third element of the response array ref is a body, and it could
be either an arrayref or L<IO::Handle>-ish object. The application could
also make use of the C<$writer> object if C<psgi.streaming> is in
effect, and in this case, the third element will not exist
(C<@$res == 2>). Dealing with these variants is again really painful,
and C<response_cb> can take care of that too, by allowing you to return
a content filter as a code reference.

  # replace all "Foo" in content body with "Bar"
  Plack::Util::response_cb($res, sub {
      my $res = shift;
      return sub {
          my $chunk = shift;
          return unless defined $chunk;
          $chunk =~ s/Foo/Bar/g;
          return $chunk;
      }
  });

The callback takes one argument C<$chunk> and your callback is
expected to return the updated chunk. If the given C<$chunk> is undef,
it means the stream has reached the end, so your callback should also
return undef, or return the final chunk and return undef when called
next time.

=head1 SEE ALSO

L<Plack> L<Plack::Builder> L<Plack::Component>

=cut
