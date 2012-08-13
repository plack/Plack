package Plack::Middleware::LogDispatch;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(logger);
use Carp ();

sub prepare_app {
    my $self = shift;
    unless ($self->logger) {
        Carp::croak "logger is not defined";
    }
}

sub call {
    my($self, $env) = @_;

    $env->{'psgix.logger'} = sub {
        my $args = shift;
        $args->{level} = 'critical' if $args->{level} eq 'fatal';
        $self->logger->log(%$args);
    };

    $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::LogDispatch - Uses Log::Dispatch to configure logger

=head1 SYNOPSIS

  use Log::Dispatch;

  my $logger = Log::Dispatch->new;
  $logger->add( Log::Dispatch::File->new(...) );
  $logger->add( Log::Dispatch::DesktopNotification->new(...) );

  builder {
      enable "LogDispatch", logger => $logger;
      $app;
  }

  # use with Log::Dispatch::Config
  use Log::Dispatch::Config;
  Log::Dispatch::Config->configure('/path/to/log.conf');

  builder {
      enable "LogDispatch", logger => Log::Dispatch::Config->instance;
      ...
  }

=head1 DESCRIPTION

LogDispatch is a L<Plack::Middleware> component that allows you to use
L<Log::Dispatch> to configure the logging object, C<psgix.logger>.

=head1 CONFIGURATION

=over 4

=item logger

L<Log::Dispatch> object to send logs to. Required.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Log::Dispatch>

L<Plack::Middleware::Log4perl>

=cut

