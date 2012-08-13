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

    return sub {
        my $respond = shift;

        my $writer;
        try {
            $res->(sub { return $writer = $respond->(@_) });
        } catch {
            if ($writer) {
                Carp::cluck $_;
                $writer->close;
            } else {
                my $res = $self->transform_error($_, $env);
                $respond->($res);
            }
        };
    };
}

sub transform_error {
    my($self, $e, $env) = @_;

    my($code, $message);
    if (blessed $e && $e->can('as_psgi')) {
        return $e->as_psgi;
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
of this will be returned directly as the PSGI response.

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

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

paste.httpexceptions L<HTTP::Exception> L<HTTP::Throwable>

=cut
