package Plack::Middleware::HTTPExceptions;
use strict;
use parent qw(Plack::Middleware);

use Carp ();
use Try::Tiny;
use Scalar::Util 'blessed';
use HTTP::Status ();

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
    if (blessed $e && $e->can('code')) {
        $code = $e->code;
        $message =
            $e->can('as_string')       ? $e->as_string :
            overload::Method($e, '""') ? "$e"          : undef;
    } else {
        $code = 500;
        $env->{'psgi.errors'}->print($e);
    }

    if ($code !~ /^[3-5]\d\d$/) {
        die $e; # rethrow
    }

    $message ||= HTTP::Status::status_message($code);

    return [ $code, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($message) ], [ $message ] ];
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
      enable "HTTPExceptions";
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::HTTPExceptions is a PSGI middleware component to
catch exceptions from applicaitions that can be translated into HTTP
status code.

Your application is supposed to throw an object that implements
C<code> method which returns the HTTP status code such as 501 or
404. This middleware catches them and creates a valid response out of
the code.

The exception object may also implement C<as_string>, or overload the
stringification, to represent the text of the error, which defaults to
the status message of error codes, such as I<Service Unavailable> for
C<503>.

There's a CPAN module L<HTTP::Exception> and they are pefect to throw
from your application to let this middleware catch and display, but
you can also implement your own exception class to throw.

All the other errors that can't be translated into HTTP errors are
just rethrown to the outer frame.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

paste.httpexceptions L<HTTP::Exception>

=cut
