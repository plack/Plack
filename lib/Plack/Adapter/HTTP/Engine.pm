package Plack::Adapter::HTTP::Engine;
use strict;
use HTTP::Engine;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub handler {
    my $self = shift;

    my $app = $self->{app}->new;

    my $engine = HTTP::Engine->new(
        interface => {
            module => 'PSGI',
            request_handler => sub { $app->request_handler(@_) },
        }
    );

    return sub { $engine->run(@_) };
}

1;

__END__

=head1 NAME

Plack::Adapter::HTTP::Engine - Adapt HTTP::Engine based app to Plack

=head1 SYNOPSIS

You already have an existent script or an application class that runs
as an HTTP::Engine handler. Here's how to run it with plackup stack.

Create a new class (or use an existent as long as it follows the
method convention) that has three methods, C<plack_adapter>, C<new>
and C<request_handler>.

  package MyHEApp;
  sub plack_adapter { 'HTTP::Engine' } # optional, but otherwise you need to specify -a manually

  sub new {
      # Do whatever
      return $self;
  }

  sub request_handler {
      my($self, $req) = @_;

      # $req is HTTP::Engine::Request. Return HTTP::Engine::Response ($res)

      return $res;
  }

Now your HTTP::Engine app is plackup-ready:

  plackup MyHEApp

=cut
