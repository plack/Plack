package Plack::Middleware::SimpleLogger;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(level);
use POSIX ();
use Scalar::Util ();

# Should this be in Plack::Util?
my $i = 0;
my %level_numbers = map { $_ => $i++ } qw(debug info warn error fatal);

sub call {
    my($self, $env) = @_;

    my $min = $level_numbers{ $self->level || "debug" };

    my $env_ref = $env;
    Scalar::Util::weaken($env_ref);

    $env->{'psgix.logger'} = sub {
        my $args = shift;

        if ($level_numbers{$args->{level}} >= $min) {
            $env_ref->{'psgi.errors'}->print($self->format_message($args->{level}, $args->{message}));
        }
    };

    $self->app->($env);
}

sub format_time {
    my $old_locale = POSIX::setlocale(&POSIX::LC_ALL);
    POSIX::setlocale(&POSIX::LC_ALL, 'C');
    my $out = POSIX::strftime(@_);
    POSIX::setlocale(&POSIX::LC_ALL, $old_locale);
    return $out;
}

sub format_message {
    my($self, $level, $message) = @_;

    my $time = format_time("%Y-%m-%dT%H:%M:%S", localtime);
    sprintf "%s [%s #%d] %s: %s\n", uc substr($level, 0, 1), $time, $$, uc $level, $message;
}

1;

__END__

=head1 NAME

Plack::Middleware::SimpleLogger - Simple logger that prints to psgi.errors

=head1 SYNOPSIS

  enable "SimpleLogger", level => "warn";

=head1 DESCRIPTION

SimpleLogger is a middleware component that formats the log message
with information such as the time and PID and prints them to
I<psgi.errors> stream, which is mostly STDERR or server log output.

=head1 SEE ALSO

L<Plack::Middleware::LogErrors>, essentially the opposite of this module

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
