package Plack::App::PSGIBin;
use strict;
use warnings;
use parent qw/Plack::App::File/;
use Plack::Util;

sub allow_path_info { 1 }

sub serve_path {
    my($self, $env, $file) = @_;

    local @{$env}{qw(SCRIPT_NAME PATH_INFO)} = @{$env}{qw( plack.file.SCRIPT_NAME plack.file.PATH_INFO )};

    my $app = $self->{_compiled}->{$file} ||= Plack::Util::load_psgi($file);
    $app->($env);
}

1;

__END__

=head1 NAME

Plack::App::PSGIBin - Run .psgi files from a directory

=head1 SYNOPSIS

  use Plack::App::PSGIBin;
  use Plack::Builder;

  my $app = Plack::App::PSGIBin->new(root => "/path/to/psgi/scripts")->to_app;
  builder {
      mount "/psgi" => $app;
  };

  # Or from the command line
  plackup -MPlack::App::PSGIBin -e 'Plack::App::PSGIBin->new(root => "/path/psgi/scripts")->to_app'

=head1 DESCRIPTION

This application loads I<.psgi> files (or actually whichever filename
extensions) from the root directory and run it as a PSGI
application. Suppose you have a directory containing C<foo.psgi> and
C<bar.psgi>, map this application to C</app> with
L<Plack::App::URLMap> and you can access them via the URL:

  http://example.com/app/foo.psgi
  http://example.com/app/bar.psgi

to load them. You can rename the file to the one without C<.psgi>
extension to make the URL look nicer, or use the URL rewriting tools
like L<Plack::Middleware::Rewrite> to do the same thing.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::CGIBin>
