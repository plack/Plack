package Plack::Adapter;
use strict;
use Carp ();
use Plack::Util;

sub adapter_for {
    my($class, $app, $adapter) = @_;

    if (!$adapter && $app =~ /\.cgi$/) {
        require Plack::Adapter::CGI;
        return Plack::Adapter::CGI->new(sub { do $app });
    } else {
        Plack::Util::load_class($app);
        $adapter ||= $app->plack_adapter if $app->can('plack_adapter');
        Carp::croak("Can't get adapter for app $app: Specify with -a or plack_adapter() method") unless $adapter;
        Plack::Util::load_class($adapter, "Plack::Adapter")->new($app);
    }
}

1;

__END__

=head1 NAME

Plack::Adapter - Adapt web applictation framework to PSGI application

=head1 SYNOPSIS

  package Plack::Adater::AwesomeFramework;
  sub new {
      my($class, $app) = @_;
      # $app is usually a class name that implements AwesomeFramework
      bless { app => $app }, $class;
  }

  sub handler {
      my $self = shift;
      return sub {
          my $env = shift;
          $self->{app}->run_psgi($env);
      };
  }

  1;

=head1 DESCRIPTION

L<Plack::Adapter> is an adapter layer to absorb the API difference
between web application frameworks. One framework might use C<< MyApp->new->run($env) >>
and others might be C<< MyApp->run_psgi($env) >>.

Writing an adapter for your web application framework allows the end
users of your framework to take the benefit of Plack utilities such as
L<plackup>. So, if you want to add PSGI support to your web
application, write a plugin or a new method that takes PSGI's C<$env>
hash ref and returns the response array ref, and name it such as
L<AwesomeFramework::Run::PSGI>. Then your framework L<supports PSGI>.

Then write a few lines of adapter code
L<Plack::Adapter::AwesomeFramework> that returns the PSGI application
(code ref) that runs your framework's run method.

And optionally, consider implementing a class method C<plack_adapter>
that returns the adapter name in your application class. For instance,
if the application class of your framework will inherit from
AwesomeFramework::App, consider adding:

  package AwesomeFramework::App;
  sub plack_adapter { 'AwesomeFramework' }

Then an user of your application framework can just use L<plackup>
without specifying the adapter themselves either by command line
option or adding a method on their code.

If your web application framework doesn't use subclassing, you can
also do mixins by exporting C<plack_adapter> or using helpers like
Catalyst::Helper.

B<DO NOT IMPLEMENT PSGI HANDLING CODE IN Plack::Adapter
NAMESPACES>. It is important to separate PSGI specific code in your
framework and then adapter code in Plack::Adapter. Take a look at
L<Catalyst::Engine::PSGI> and L<Plack::Adapter::Catalyst> to see what
I mean.

=cut
