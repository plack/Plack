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

  starman -L Delayed

=head1 DESCRIPTIOM

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<plackup>

=cut

