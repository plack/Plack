package Plack::Middleware::HTTPExceptions;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(rethrow);

use Carp ();
use Try::Tiny;
use Scalar::Util 'blessed';
use HTTP::Status ();

sub prepare_app {
    my $self = shift;
    $self->rethrow(1) if ($ENV{PLACK_ENV} || '') eq 'development';
}

sub call {
    my($self, $env) = @_;

    my $res = try {
        $self->app->($env);
    } catch {
        $self->transform_error($_, $env);
    };

    return $res if ref $res eq 'ARRAY';

    my $unroll_coderef_responses;
    $unroll_coderef_responses = sub {
        my ($responder, $response)  = @_;
        my $writer;
        try {
            $response->(sub { return $writer = $responder->(@_) });
        } catch {
          if($writer) {
              # In the case where the exception happens part way through a write
              # We just die since we can't at this point change the response
              Carp::cluck $_;
              $writer->close;
          } else {
            my $error_psgi_response = $self->transform_error($_, $env);
            return $responder->($error_psgi_response) if ref $error_psgi_response eq 'ARRAY';
            return $unroll_coderef_responses->($responder, $error_psgi_response);
          }
        };
    };

    return sub {
        my $responder = shift;
        return $unroll_coderef_responses->($responder, $res);
    };
}

sub transform_error {
    my($self, $e, $env) = @_;

    my($code, $message);
    if (blessed $e && $e->can('as_psgi')) {
        return $e->as_psgi($env);
    }
    if (blessed $e && $e->can('code')) {
        $code = $e->code;
        $message =
            $e->can('as_string')       ? $e->as_string :
            overload::Method($e, '""') ? "$e"          : undef;
    } else {
        if ($self->rethrow) {
            die $e;
        }
        else {
            $code = 500;
            $env->{'psgi.errors'}->print($e);
        }
    }

    if ($code !~ /^[3-5]\d\d$/) {
        die $e; # rethrow
    }

    $message ||= HTTP::Status::status_message($code);

    my @headers = (
         'Content-Type'   => 'text/plain',
         'Content-Length' => length($message),
    );

    if ($code =~ /^3/ && (my $loc = eval { $e->location })) {
        push(@headers, Location => $loc);
    }

    return [ $code, \@headers, [ $message ] ];
}

1;

__END__

=head1 NAME

Plack::Middleware::HTTPExceptions - Catch HTTP exceptions

=head1 SYNOPSIS

  use HTTP::Exception;

  my $app = sub {
      # ...
      HTTP::Exception::500->throw;
  };

  builder {
      enable "HTTPExceptions", rethrow => 1;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::HTTPExceptions is a PSGI middleware component to
catch exceptions from applications that can be translated into HTTP
status codes.

Your application is supposed to throw an object that implements a
C<code> method which returns the HTTP status code, such as 501 or
404. This middleware catches them and creates a valid response out of
the code. If the C<code> method returns a code that is not an HTTP
redirect or error code (3xx, 4xx, or 5xx), the exception will be
rethrown.

The exception object may also implement C<as_string> or overload
stringification to represent the text of the error. The text defaults to
the status message of the error code, such as I<Service Unavailable> for
C<503>.

Finally, the exception object may implement C<as_psgi>, and the result
of this will be returned directly as the PSGI response.  When calling
the C<as_psgi> method, the PSGI C<$env> will be passed.

If the code is in the 3xx range and the exception implements the 'location'
method (HTTP::Exception::3xx does), the Location header will be set in the
response, so you can do redirects this way.

There are CPAN modules L<HTTP::Exception> and L<HTTP::Throwable>, and
they are perfect to throw from your application to let this middleware
catch and display, but you can also implement your own exception class
to throw.

If the thrown exception is not an object that implements either a
C<code> or an C<as_psgi> method, a 500 error will be returned, and the
exception is printed to the psgi.errors stream.
Alternatively, you can pass a true value for the C<rethrow> parameter
for this middleware, and the exception will instead be rethrown. This is
enabled by default when C<PLACK_ENV> is set to C<development>, so that
the L<StackTrace|Plack::Middleware::StackTrace> middleware can catch it
instead.

=head1 NOTES

In the case where an exception rises during the middle of a streaming
response (such as the following):

    my $psgi_app = sub {
    my $env = shift;
        return sub {
        my $responder = shift;
        my $writer = $responder->([200, ['content-type'=>'text/html']]);
        $writer->write('ok');

        # Stuff...

        die MyApp::Exception::ServerError->new($env);
    };

We can't meaningfully set the response from this exception, since at this
point HTTP Headers and a partial body have been returned.  If you need to
verify such a case you'll need to rely on alternative means, such as setting
expected content-length or providing a checksum, that the client can use to
valid the returned content.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

paste.httpexceptions L<HTTP::Exception> L<HTTP::Throwable>

=cut
