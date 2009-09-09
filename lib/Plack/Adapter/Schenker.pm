package Plack::Adapter::Schenker;
use strict;
use warnings;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'PSGI',
            request_handler => sub { Schenker::request_handler(@_) },
        }
    );

    Schenker::init;
    return sub { Schenker::Engine->run(@_) };
}

1;

__END__

=head1 NAME

Plack::Adapter::Schenker - Adapter to run Schenker apps in Plack

=head1 DESCRIPTION

Rename your C<foo.pl> to C<Foo.pm> and then your app is Schenker ready:

  plackup -a Schenker Foo

You can optionally implement C<plack_adapter> method to return the
string C<Schenker> to avoid passing C<-a> option every time.

=cut
