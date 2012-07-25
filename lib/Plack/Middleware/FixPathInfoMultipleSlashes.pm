package Plack::Middleware::FixPathInfoMultipleSlashes;

use strict;
use parent 'Plack::Middleware';
use URI::Escape;
use URI;

sub call {
    my($self, $env) = @_;

    # lighttpd and apache munge multiple slashes in PATH_INFO into one. Try recovering it
    my $uri = URI->new("http://localhost" .  $env->{REQUEST_URI});
    $env->{PATH_INFO} = uri_unescape($uri->path);
    $env->{PATH_INFO} =~ s/^\Q$env->{SCRIPT_NAME}\E//;

    return $self->app->($env);
}

1;

__END__

=head1 NAME

Plack::Middleware::FixPathInfoMultipleSlashes - fixes wrong PATH_INFO that lighttpd and apache generate by munging multiple slashes to one

=head1 SYNOPSIS

  # in your app.psgi
  use Plack::Builder;

  builder {
    enable "FixPathInfoMultipleSlashes";
    $app;
  };

  # Or from the command line
  plackup -s FCGI -e 'enable "FixPathInfoMultipleSlashes"' /path/to/app.psgi

=head1 DESCRIPTION

This middleware fixes wrong C<PATH_INFO> set by lighttpd and apache which munge multiple slashes to a single slash.

This middleware is not applied automatically, as it can break use of mod_rewrite when prepending things to the C<PATH_INFO>.

=head1 AUTHORS

Tomas Doran, Tatsuhiko Miyagawa, cho45

=cut

