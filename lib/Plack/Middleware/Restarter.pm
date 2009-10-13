package Plack::Middleware::Restarter;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use File::ChangeNotify;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    $args{filter} ||= qr{\.(pm|yml|yaml|conf)$};
    bless {%args}, $class;
}

sub to_app {
    my $self = shift;
    my $pid = fork();
    if (!defined($pid)) {
        die "cannot fork: '$!'";
    } elsif ($pid > 0) {
        # parent(watcher process)
        close STDOUT;
        close STDIN;

        local $SIG{CHLD} = sub { exit }; # exit when child was dead.
        my $watcher = File::ChangeNotify->instantiate_watcher(
            %$self
        );
        while ( my @events = $watcher->wait_for_events() ) {
            kill 'HUP' => $pid;
            waitpid($pid, 0);
            exit;
        }
    } else {
        # child(main process)
        return $self->app(); # nop. This is same as 'sub { $self->app->(@_) }'
    }
}

1;
__END__

=head1 NAME

Plack::Middleware::Restarter - Restart the standalone server

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable "Plack::Middleware::Restarter";
      $app;
  };

=head1 DESCRIPTION

This middleware forks the main standalone server and creates a watcher
that watches the filesystem in the current directory and restarts the
server process by sending HUP when it finds an updated file. This
middleware might be handy for a quick restart in the development but
not recommended to use on the production environment.

=head1 CONFIGURATION

=over 4

=item directories

  enable "Plack::Middleware::Restarter",
      directories => "/path/to/app";

Specifies which directory to watch for file updates. Defaults to C<.> (current directory).

=item filter

  enable "Plack::Middleware::Restarter",
      filter => qr/\.pm$/;

The regular expression filter to match what files to watch for updates. Defaults to C<\.(pm|yml|yaml|conf)$>.

=back

=head1 PORTABILITY

This module might not work on Win32/VMS systems.

=head1 AUTHOR

Tokuhiro Matsuno

=cut

