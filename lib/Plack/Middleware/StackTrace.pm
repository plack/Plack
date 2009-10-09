package Plack::Middleware::StackTrace;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use Plack;
use Plack::Util;
use Data::Dump;
use Devel::StackTrace;
use Devel::StackTrace::AsHTML;

our $StackTraceClass = "Devel::StackTrace";

# Optional since it needs PadWalker
if (eval { require Devel::StackTrace::WithLexicals; 1 }) {
    $StackTraceClass = "Devel::StackTrace::WithLexicals";
}

sub call {
    my($self, $env) = @_;

    my $trace;
    local $SIG{__DIE__} = sub {
        $trace = $StackTraceClass->new;
        die @_;
    };

    my $res = do {
        local $@;
        eval { $self->app->($env) };
    };

    if (!$res && $trace) {
        my $body = $trace->as_html;
        $res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ $body ]];
    }

    return $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::StackTrace - Displays stack trace when your app dies

=head1 SYNOPSIS

  enable Plack::Middleware::StackTrace;

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen.

This middleware is enabled by default when you run L<plackup> in the
default development mode.

=head1 CONFIGURATION

No configuration option is available.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<CGI::ExceptionManager> L<Plack::Middleware>

=cut

