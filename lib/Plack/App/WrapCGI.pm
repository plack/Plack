package Plack::App::WrapCGI;
use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(script _app);
use CGI::Emulate::PSGI;
use CGI::Compile;
use Carp;

sub prepare_app {
    my $self = shift;
    my $script = $self->script
        or croak "'script' is not set";

    my $sub = CGI::Compile->compile($script);
    my $app = CGI::Emulate::PSGI->handler($sub);

    $self->_app($app);
}

sub call {
    my($self, $env) = @_;
    $self->_app->($env);
}

1;

__END__

=head1 NAME

Plack::App::WrapCGI - Compiles a CGI script as PSGI application

=head1 SYNOPSIS

  use Plack::App::WrapCGI;

  my $app = Plack::App::WrapCGI->new(script => "/path/to/script.pl")->to_app;

=head1 DESCRIPTION

Plack::App::WrapCGI compiles a CGI script into a PSGI application
using L<CGI::Compile> and L<CGI::Emulate::PSGI>, and runs it with any
PSGI server as a PSGI application.

See also L<Plack::App::CGIBin> if you have a directory that contains a
lot of CGI scripts and serve them like Apache's mod_cgi.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::CGIBin>

=cut
