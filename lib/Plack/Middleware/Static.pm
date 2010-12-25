package Plack::Middleware::Static;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::File;

use Plack::Util::Accessor qw( path root encoding pass_through );

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle_static($env);
    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _handle_static {
    my($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($_) : $_ =~ $path_match;
        return unless $matched;
    }

    $self->{file} ||= Plack::App::File->new({ root => $self->root || '.', encoding => $self->encoding });
    local $env->{PATH_INFO} = $path; # rewrite PATH
    return $self->{file}->call($env);
}

1;
__END__

=head1 NAME

Plack::Middleware::Static - serve static files with Plack

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable "Plack::Middleware::Static",
          path => qr{^/(images|js|css)/}, root => './htdocs/';
      $app;
  };

=head1 DESCRIPTION

Enable this middleware to allow your Plack-based application to serve
static files.

If the given request matches with the pattern defined in C<path>, this
middleware will try to locate the file in C<root>. If the file exists
it will be served but otherwise C<404> response will be returned. See
C<pass_through> option below to change this behavior.

If the requested document is not within the C<root> (i.e. directory
traversal) or the file is there but not readable, a 403 Forbidden
response will be returned.

The content type returned will be determined from the file extension
based on L<Plack::MIME>.

=head1 CONFIGURATIONS

=over 4

=item path, root

  enable "Plack::Middleware::Static",
      path => qr{^/static/}, root => 'htdocs/';

C<path> specifies the URL pattern (regular expression) or a callback
to match with requests to serve static files for. C<root> specifies
the root directory to serve those static files from. The default value
of C<root> is the current directory.

This examples configuration serves C</static/foo.jpg> from
C<htdocs/static/foo.jpg>. Note that the matched C</static/> portion is
still appears in the local mapped path. If you don't like it, use a
callback instead to munge C<$_>:

  enable "Plack::Middleware::Static",
      path => sub { s!^/static/!! }, root => 'static-files/';

This configuration would serve C</static/foo.png> from
C<static-files/foo.png> (not C<static-files/static/foo.png>). The
callback specified in C<path> option matches against C<$_> and then
updates the value since it does s///, and returns the number of
matches, so it will pass through when C</static/> doesn't match.

If you want to map multiple static directories from different root,
simply add "this", middleware multiple times with different
configuration options.

=item pass_through

By turning on this option, this middleware will pass the request
back to the application for further processing, if the incoming
request path matches with the C<path> but the requested file is not
found on the file system.

=back

=head1 AUTHOR

Tokuhiro Matsuno, Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Builder>

=cut


