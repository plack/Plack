package Plack::Middleware::Log4perl;
use strict;
use parent qw(Plack::Middleware);
use Plack::Util::Accessor qw(category logger conf);
use Carp ();

sub prepare_app {
    my $self = shift;

    if ($self->conf) {
        require Log::Log4perl;
        Log::Log4perl::init($self->conf);
    }

    # NOTICE: if category = '0' you must not change it by '' (root logger)
    $self->logger( Log::Log4perl->get_logger( defined $self->category ? $self->category : '' ) );
}

sub call {
    my($self, $env) = @_;

    $env->{'psgix.logger'} = sub {
        my $args = shift;
        my $level = $args->{level};
        local $Log::Log4perl::caller_depth
            = $Log::Log4perl::caller_depth + 1;
        $self->logger->$level($args->{message});
    };

    $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::Log4perl - Uses Log::Log4perl to configure logger

=head1 SYNOPSIS

  my $app = sub {
      my $env =  shift;

      $env->{'psgix.logger'}({ level => 'error', message => 'Hi' });

      return [
          '200',
          [ 'Content-Type' => 'text/plain' ],
          [ "Hello World" ],
      ];
  };


  # Use your own Log4perl configuration
  use Log::Log4perl;
  Log::Log4perl::init('/path/to/log4perl.conf');

  builder {
      # tell the logger to log with 'plack' category
      enable "Log4perl", category => "plack";
      $app;
  }


  # Configure with Log4perl middleware options
  builder {
      enable "Log4perl", category => "plack", conf => '/path/to/log4perl.conf';
      $app;
  }

=head1 DESCRIPTION

Log4perl is a L<Plack::Middleware> component that allows you to use
L<Log::Log4perl> to configure the logging object C<psgix.logger> for a
given category.

=head1 CONFIGURATION

=over 4

=item category

The C<log4perl> category to send logs to. Defaults to C<''> which means
it send to the root logger.

=item conf

The configuration file path (or a scalar ref containing the config
string) for L<Log::Log4perl> to automatically configure.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Log::Log4perl>

L<Plack::Middleware::LogDispatch>

=cut

