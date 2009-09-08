package Plack::Loader;
use Carp ();
use Plack::Util;

sub auto {
    my($class, %args) = @_;

    my $impl = $class->guess
        or Carp::croak("Couldn't auto-guess implementation. Set it with PLACK_IMPL");
    Plack::Util::load_class($impl, "Plack::Impl")->new(%args);
}

sub load {
    my($class, $impl, @args) = @_;
    Plack::Util::load_class($impl, "Plack::Impl")->new(@args);
}

sub guess {
    my $class = shift;

    return $ENV{PLACK_IMPL} if $ENV{PLACK_IMPL};

    if ($ENV{PHP_FCGI_CHILDREN}) {
        return "FCGI";
    } elsif ($ENV{MOD_PERL}) {
        return "ModPerl";
    } elsif ($ENV{GATEWAY_INTERFACE}) {
        return "CGI";
    } elsif (exists $INC{"Mojo.pm"}) {
        return "Mojo";
    } elsif (exists $INC{"AnyEvent.pm"}) {
        return "AnyEvent";
    } else {
        return "ServerSimple";
    }
}

1;

__END__

=head1 NAME

Plack::Loader - (auto)load Plack implementation

=head1 SYNOPSIS

  # auto-select implementations based on env vars
  use Plack::Loader;
  Plack::Loader->auto(%args)->run($app);

  # specify the implementation with a name
  Plack::Loader->load('ServerSimple', %args)->run($app);

=head1 DESCRIPTION

Plack::Loader is a factory class to load one of Plack::Impl subclasses based on the environment.

=head1 AUTOLOADING

C<< Plack::Loader->auto(%args) >> will autoload the most correct
implementation by guessing from environment variables and Perl INC
hashes.

=over 4

=item PLACK_IMPL

  env PLACK_IMPL=ServerSimple ...

Plack users can specify the specific implementation they want to load
using the C<PLACK_IMPL> environment variable.

=item MOD_PERL, PHP_FCGI_CHILDREN, GATEWAY_INTERFACE

If there's one of mod_perl, FastCGI or CGI specific environment
variables is set, use the corresponding implementation.

=item %INC

If C<AnyEvent.pm> or C<Mojo.pm> is loaded, the implementation will be loaded.

=back

=cut


