package Plack::Loader;
use strict;
use Carp ();
use Plack::Util;

sub auto {
    my($class, %args) = @_;

    my $server = $class->guess
        or Carp::croak("Couldn't auto-guess server serverementation. Set it with PLACK_SERVER");
    Plack::Util::load_class($server, "Plack::Server")->new(%args);
}

sub load {
    my($class, $server, @args) = @_;
    Plack::Util::load_class($server, "Plack::Server")->new(@args);
}

sub guess {
    my $class = shift;

    return $ENV{PLACK_SERVER} if $ENV{PLACK_SERVER};

    if ($ENV{PHP_FCGI_CHILDREN} || $ENV{FCGI_ROLE} || $ENV{FCGI_SOCKET_PATH}) {
        return "FCGI";
    } elsif ($ENV{MOD_PERL}) {
        return "ModPerl";
    } elsif ($ENV{GATEWAY_INTERFACE}) {
        return "CGI";
    } elsif (exists $INC{"AnyEvent.pm"}) {
        return "AnyEvent";
    } else {
        return "Standalone";
    }
}

1;

__END__

=head1 NAME

Plack::Loader - (auto)load Plack Servers

=head1 SYNOPSIS

  # auto-select server backends based on env vars
  use Plack::Loader;
  Plack::Loader->auto(%args)->run($app);

  # specify the implementation with a name
  Plack::Loader->load('ServerSimple', %args)->run($app);

=head1 DESCRIPTION

Plack::Loader is a factory class to load one of Plack::Server subclasses based on the environment.

=head1 AUTOLOADING

C<< Plack::Loader->auto(%args) >> will autoload the most correct
server implementation by guessing from environment variables and Perl INC
hashes.

=over 4

=item PLACK_SERVER

  env PLACK_SERVER=ServerSimple ...

Plack users can specify the specific implementation they want to load
using the C<PLACK_SERVER> environment variable.

=item MOD_PERL, PHP_FCGI_CHILDREN, GATEWAY_INTERFACE

If there's one of mod_perl, FastCGI or CGI specific environment
variables is set, use the corresponding server implementation.

=item %INC

If C<AnyEvent.pm> is loaded, the implementation will be loaded.

=back

=cut


