package Plack::Middleware::StackTrace;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Devel::StackTrace;
use Devel::StackTrace::AsHTML;
use Try::Tiny;

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

    my $res = try { $self->app->($env) };

    if ($trace && (!$res or $res->[0] == 500)) {
        if (($env->{HTTP_ACCEPT} || '*/*') =~ /html/) {
            $res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ utf8_safe($trace->as_html) ]];
        } else {
            $res = [500, ['Content-Type' => 'text/plain; charset=utf-8'], [ utf8_safe($trace->as_string) ]];
        }
    }

    # break $trace here since $SIG{__DIE__} holds the ref to it, and
    # $trace has refs to Standalone.pm's args ($conn etc.) and
    # prevents garbage collection to be happening.
    undef $trace;

    return $res;
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

  enable "Plack::Middleware::StackTrace";

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen.

This middleware is enabled by default when you run L<plackup> in the
default development mode.

=head1 CONFIGURATION

No configuration option is available.

=head1 AUTHOR

Tokuhiro Matsuno

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Devel::StackTrace::AsHTML> L<Plack::Middleware>

=cut

