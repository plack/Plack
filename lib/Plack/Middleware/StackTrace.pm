package Plack::Middleware::StackTrace;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Devel::StackTrace;
use Devel::StackTrace::AsHTML;
use Try::Tiny;
use Plack::Util::Accessor qw( force no_print_errors );

our $StackTraceClass = "Devel::StackTrace";

# Optional since it needs PadWalker
if ($ENV{PLACK_STACKTRACE_LEXICALS} && try { require Devel::StackTrace::WithLexicals; 1 }) {
    $StackTraceClass = "Devel::StackTrace::WithLexicals";
}

sub call {
    my($self, $env) = @_;

    my $trace;
    local $SIG{__DIE__} = sub {
        $trace = $StackTraceClass->new;
        die @_;
    };

    my $caught;
    my $res = try { $self->app->($env) } catch { $caught = $_ };

    if ($trace && ($caught || ($self->force && ref $res eq 'ARRAY' && $res->[0] == 500)) ) {
        my $text = trace_as_string($trace);
        $env->{'psgi.errors'}->print($text) unless $self->no_print_errors;
        if (($env->{HTTP_ACCEPT} || '*/*') =~ /html/) {
            $res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ utf8_safe($trace->as_html) ]];
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

sub trace_as_string {
    my $trace = shift;

    my $st = '';
    my $first = 1;
    foreach my $f ( $trace->frames() ) {
        $st .= "\t" unless $first;
        $st .= $f->as_string($first) . "\n";
        $first = 0;
    }

    return $st;

}

sub utf8_safe {
    my $str = shift;

    # NOTE: I know messing with utf8:: in the code is WRONG, but
    # because we're running someone else's code that we can't
    # guarnatee which encoding an exception is encoded, there's no
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
application and displays nice stack trace screen.

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

