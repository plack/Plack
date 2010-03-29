package Plack::Loader::Delayed;
use strict;
use parent qw(Plack::Loader);

sub preload_app {
    my($self, $builder) = @_;
    $self->{builder} = $builder;
}

sub run {
    my($self, $server) = @_;

    # so servers can call this to replace $app (e.g. Starman child init hook)
    $server->{psgi_app_builder} = $self->{builder};

    my $compiled;
    my $app = sub {
        $compiled ||= $self->{builder}->();
        $compiled->(@_);
    };

    $server->run($app);
}

1;

__END__

=head1 NAME

Plack::Loader::Delayed - Delay load the application

=head1 SYNOPSIS

  plackup -L Delayed

=head1 DESCRIPTION

Delayed loader delays the compilation of your application until the
first request by default. This should be useful if you want to delay
load the application in forking server implementations such as
L<Starman> or L<Starlet> to avoid sharing sockets or database
connections when the application is compiled in the parent process.

Delaying the compilation of your application kills the benefit of
preloading modules in copy-on-write friendly environment. To avoid
that, you can still preload the modules with the C<-M> command line
options.

  plackup -s Starlet --max-workers 10 -MMyApp -L Delayed myapp.psgi

would C<use> your MyApp module in the master parent process but
C<myapp.psgi> compilation is done on the first request per children.

=head1 SERVER IMPLEMENTATIONS

PSGI servers can extend the behavior of this loader by looking at
C<psgi_app_builder> callback set in L<Plack::Handler> object. For
instance, L<Starman> when used with this loader, compiles the
application as soon as a new child process is forked, rather than in
the first request time.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<plackup> L<Plack::Loader::Shotgun>

=cut
