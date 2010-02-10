package Plack::App::CGIBin;
use strict;
use warnings;
use parent qw/Plack::App::File/;
use Plack::App::WrapCGI;

sub allow_path_info { 1 }

sub serve_path {
    my($self, $env, $file) = @_;

    my $app = $self->{_compiled}->{$file} ||= Plack::App::WrapCGI->new(script => $file);
    $app->($env);
}

1;

__END__

=head1 NAME

Plack::App::CGIBin - cgi-bin replacement for Plack servers

=head1 SYNOPSIS

  use Plack::App::CGIBin;
  use Plack::Builder;

  my $app = Plack::App::CGIBin->new(root => "/path/to/cgi-bin")->to_app;
  builder {
      mount "/cgi-bin" => $app;
  };

  # Or from the command line
  plackup -MPlack::App::CGIBin -e 'Plack::App::CGIBin->new(root => "/path/to/cgi-bin")->to_app'

=head1 DESCRIPTION

Plack::App::CGIBin allows you to load CGI scripts from a directory and
convert them into a (persistent) PSGI application. This application
uses L<CGI::Compile> to compile a cgi script into a sub (like
L<ModPerl::Registry>) and then run it using L<CGI::Emulate::PSGI>.

This would give you the extreme easiness when you have bunch of old
CGI scripts that is loaded using I<cgi-bin> of Apache web server.

This module does not (yet) stat files nor recompile files on every
request for the interest of performance. You need to restart the
server process to reflect the changes to the CGI scripts.

See also L<Plack::App::WrapCGI> if you compile one CGI script into a
PSGI application without serving CGI scripts from a directory, to
remove overhead of filesystem lookups, etc.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::File> L<CGI::Emulate::PSGI> L<CGI::Compile> L<Plack::App::WrapCGI>

=cut
