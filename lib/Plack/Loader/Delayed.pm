package Plack::Loader::Delayed;
use strict;
use parent qw(Plack::Loader);

sub preload_app {
    my($self, $builder) = @_;
    $self->{builder} = $builder;
}

sub run {
    my($self, $server) = @_;

    my $compiled;
    my $app = sub {
        $compiled ||= $self->{builder}->();
        $compiled->(@_);
    };

    $server->{psgi_app_builder} = $self->{builder};
    $server->run($app);
}

1;

__END__

=head1 NAME

Plack::Loader::Delayed - Delay the loading of .psgi until the first run

=head1 SYNOPSIS

  plackup -s Starlet -L Delayed myapp.psgi

=head1 DESCRIPTION

This loader delays the compilation of specified PSGI application until
the first request time. This prevents bad things from happening with
preforking web servers like L<Starlet>, when your application
manipulates resources such as sockets or database connections in the
master startup process and then shared by children.

You can combine this loader with C<-M> command line option, like:

  plackup -s Starlet -MCatalyst -L Delayed myapp.psgi

loads the module Catalyst in the master process for the better process
management with copy-on-write, however the application C<myapp.psgi>
is loaded per children.

L<Starman> since version 0.2000 loads this loader by default unless
you specify the command line option C<--preload-app> for the
L<starman> executable.

=head1 DEVELOPERS

Web server developers can make use of C<psgi_app_builder> attribute
callback set in Plack::Handler, to load the application earlier than
the first request time.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<plackup>

=cut

