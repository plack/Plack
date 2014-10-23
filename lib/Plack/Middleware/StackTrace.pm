package Plack::Middleware::StackTrace;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Devel::StackTrace;
use Devel::StackTrace::AsHTML;
use Scalar::Util qw( refaddr );
use Try::Tiny;
use Plack::Util::Accessor qw( force no_print_errors );

our $StackTraceClass = "Devel::StackTrace";

# Optional since it needs PadWalker
if (try { require Devel::StackTrace::WithLexicals; Devel::StackTrace::WithLexicals->VERSION(0.08); 1 }) {
    $StackTraceClass = "Devel::StackTrace::WithLexicals";
}

sub call {
    my($self, $env) = @_;

    my ($trace, %string_traces, %ref_traces);
    local $SIG{__DIE__} = sub {
        $trace = $StackTraceClass->new(
            indent => 1, message => munge_error($_[0], [ caller ]),
            ignore_package => __PACKAGE__, no_refs => 1,
        );
        if (ref $_[0]) {
            $ref_traces{refaddr($_[0])} ||= $trace;
        }
        else {
            $string_traces{$_[0]} ||= $trace;
        }
        die @_;
    };

    my $caught;
    my $res = try {
        $self->app->($env);
    } catch {
        $caught = $_;
        [ 500, [ "Content-Type", "text/plain; charset=utf-8" ], [ no_trace_error(utf8_safe($caught)) ] ];
    };

    if ($caught) {
        # Try to find the correct trace for the caught exception
        my $caught_trace;
        if (ref $caught) {
            $caught_trace = $ref_traces{refaddr($caught)};
        }
        else {
            # This is not guaranteed to work if multiple exceptions with
            # the same message are thrown.
            $caught_trace = $string_traces{$caught};
        }
        $trace = $caught_trace if $caught_trace;
    }

    if ($trace && ($caught || ($self->force && ref $res eq 'ARRAY' && $res->[0] == 500)) ) {
        my $text = $trace->as_string;
        my $html = $trace->as_html;
        $env->{'plack.stacktrace.text'} = $text;
        $env->{'plack.stacktrace.html'} = $html;
        $env->{'psgi.errors'}->print($text) unless $self->no_print_errors;
        if (($env->{HTTP_ACCEPT} || '*/*') =~ /html/) {
            $res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ utf8_safe($html) ]];
        } else {
            $res = [500, ['Content-Type' => 'text/plain; charset=utf-8'], [ utf8_safe($text) ]];
        }
    }

    # break $trace here since $SIG{__DIE__} holds the ref to it, and
    # $trace has refs to Standalone.pm's args ($conn etc.) and
    # prevents garbage collection to be happening.
    undef $trace;

    return $res;
}

sub no_trace_error {
    my $msg = shift;
    chomp($msg);

    return <<EOF;
The application raised the following error:

  $msg

and the StackTrace middleware couldn't catch its stack trace, possibly because your application overrides \$SIG{__DIE__} by itself, preventing the middleware from working correctly. Remove the offending code or module that does it: known examples are CGI::Carp and Carp::Always.
EOF
}

sub munge_error {
    my($err, $caller) = @_;
    return $err if ref $err;

    # Ugly hack to remove " at ... line ..." automatically appended by perl
    # If there's a proper way to do this, please let me know.
    $err =~ s/ at \Q$caller->[1]\E line $caller->[2]\.\n$//;

    return $err;
}

sub utf8_safe {
    my $str = shift;

    # NOTE: I know messing with utf8:: in the code is WRONG, but
    # because we're running someone else's code that we can't
    # guarantee which encoding an exception is encoded, there's no
    # better way than doing this. The latest Devel::StackTrace::AsHTML
    # (0.08 or later) encodes high-bit chars as HTML entities, so this
    # path won't be executed.
    if (utf8::is_utf8($str)) {
        utf8::encode($str);
    }

    $str;
}

1;

__END__

=head1 NAME

Plack::Middleware::StackTrace - Displays stack trace when your app dies

=head1 SYNOPSIS

  enable "StackTrace";

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen. The stack trace is
also stored in the environment as a plaintext and HTML under the key
C<plack.stacktrace.text> and C<plack.stacktrace.html> respectively, so
that middleware further up the stack can reference it.

This middleware is enabled by default when you run L<plackup> in the
default I<development> mode.

You're recommended to use this middleware during the development and
use L<Plack::Middleware::HTTPExceptions> in the deployment mode as a
replacement, so that all the exceptions thrown from your application
still get caught and rendered as a 500 error response, rather than
crashing the web server.

Catching errors in streaming response is not supported.

=head1 CONFIGURATION

=over 4

=item force

  enable "StackTrace", force => 1;

Force display the stack trace when an error occurs within your
application and the response code from your application is
500. Defaults to off.

The use case of this option is that when your framework catches all
the exceptions in the main handler and returns all failures in your
code as a normal 500 PSGI error response. In such cases, this
middleware would never have a chance to display errors because it
can't tell if it's an application error or just random C<eval> in your
code. This option enforces the middleware to display stack trace even
if it's not the direct error thrown by the application.

=item no_print_errors

  enable "StackTrace", no_print_errors => 1;

Skips printing the text stacktrace to console
(C<psgi.errors>). Defaults to 0, which means the text version of the
stack trace error is printed to the errors handle, which usually is a
standard error.

=back

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Devel::StackTrace::AsHTML> L<Plack::Middleware> L<Plack::Middleware::HTTPExceptions>

=cut

