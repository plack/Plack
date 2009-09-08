package Plack::Impl;
use strict;
use Carp ();

sub auto {
    my($class, %args) = @_;

    my $impl = $class->guess
        or Carp::croak("Couldn't auto-guess implementation. Set it with PSGI_PLACK_IMPL");
    $class->create($impl);
}

sub create {
    my($class, $impl, @args) = @_;
    $impl = "Plack::Impl::$impl";

    my $file = $impl;
    $file =~ s!::!/!g;
    require "$file.pm";

    return $impl->new(@args);
}

sub guess {
    my $class = shift;

    return $ENV{PSGI_PLACK_IMPL} if $ENV{PSGI_PLACK_IMPL};

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
        return;
    }
}

1;

__END__

=head1 NAME

Plack::Impl - Standard interface for Plack implementations

=head1 SYNOPSIS

  my $impl = Plack::Impl::XXX->new(%args);
  $impl->run($app);

  # auto-select implementations based on env vars
  use Plack::Impl;
  Plack::Impl->auto(%args)->run;

=head1 DESCRIPTION

Plack::Impl subclasses are supposed to implement a pretty simple unified interface to run the PSGI application.

=head1 METHODS

=over 4

=item new

  $impl = Plack::Impl::XXX->new(%args);

Creates a new implementation object. I<%args> can take arbitrary
parameters per implementations but common parameters are:

=over 8

=item port

Port number the server listens to.

=item address

Address the server listens to. Set to undef to listen any interface.

=back

=over 4

=item run

  $impl->run($app)

Starts the server process and when a request comes in, run the PSGI application passed in C<$app>.

=back

=head1 SEE ALSO

rackup

=cut

