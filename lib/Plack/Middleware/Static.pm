package Plack::Middleware::Static;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use File::Spec;
use File::Spec::Unix;
use Path::Class 'dir';
use HTTP::Date;
use Cwd ();

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    # TODO use MIME::Types?
    $args{mime_types} = {
        jpg   => 'image/jpeg',
        jpeg  => 'image/jpeg',
        png   => 'image/png',
        mp3   => 'audio/mpeg',
        '3g2' => 'video/3gpp2',
        '3gp' => 'video/3gpp',
        flv   => 'video/x-flv',
        html  => 'text/html',
        htm   => 'text/html',
        css   => 'text/css',
        csv   => 'text/csv',
        bmp   => 'image/x-bmp',
        ico   => 'image/vnd.microsoft.icon',
        svg   => 'image/svg+xml',
        gif   => 'image/gif',
        gz    => 'application/x-gzip',
        %{ $args{mime_types} || +{} },
    };
    return bless {enable_404_handler => 1, %args}, $class;
}

sub to_app {
    my $self = shift;

    return sub {
        my ($env, @args) = @_;

        my $res = $self->_handle_static($env);
        return $res if $res;

        return $self->app->($env, @args);
    };
}

# Using the rules attribute, return a static document if any matches, or undefined otherwise.
sub _handle_static {
    my ($self, $env) = @_;
    for my $rule (@{$self->{rules}}) {
        if ($env->{PATH_INFO} =~ $rule->{path}) {
            my $docroot = dir($rule->{root});
            my $file = $docroot->file(File::Spec::Unix->splitpath($env->{PATH_INFO}));
            my $realpath = Cwd::realpath($file->absolute->stringify);

            # Is the requested path within the root?
            if ($realpath && !$docroot->subsumes($realpath)) {
                return [403, ['Content-Type' => 'text/plain'], ['forbidden']];
            }
            # Does the file actually exist?
            if (!$realpath || !-f $file) {
                return unless $self->{enable_404_handler};
                return [404, ['Content-Type' => 'text/plain'], ['not found']];
            }
            # If the requested file present but lacking the permission to read it?
            if (!-r $file) {
                return [403, ['Content-Type' => 'text/plain'], ['forbidden']];
            }

            my $content_type = do {
                my $type;
                if ($file =~ /.*\.(\S{1,})$/xms ) {
                    $type = $self->{mime_types}->{$1};
                }
                $type ||= 'text/plain';
                $type;
            };

            my $fh = $file->openr;
            die "Unable to open $file for reading : $!" unless $fh;
            binmode $fh;

            my $stat = $file->stat;
            return [
                200,
                [
                    'Content-Type'   => $content_type,
                    'Content-Length' => $stat->size,
                    'Last-Modified'  => HTTP::Date::time2str( $stat->mtime )
                ],
                $fh
            ];
        }
    }
    return; # fallthrough
}

1;
__END__

=head1 NAME

Plack::Middleware::Static - serve static files with Plack

=head1 SYNOPSIS

  use Plack::Builder;
  use Plack::Middleware qw(Static);

  builder {
      enable Plack::Middleware::Static
          rules => [
              {
                 path => qr{^/static/},
                 root => './htdocs/',
              }
          ],
          enable_404_handler => 0;
      $app;
  };

=head1 DESCRIPTION

Enable this middleware to allow your Plack-based application to serve static
files. If a static file exists for the requested path, it will be served.
Otherwise, the request will be passed on to the application for further
processing.

If the requested document is not within the C<root>, we'll return a 403 status
code with a plain "forbidden" message. We'll return the same response if the is
present but not readable. Currently there is no way to customize the content
for these responses.

The content type returned will be determined from the file extension and our
mapping of file extension to mime types. See the C<mime_types> attribute below
on how to customize this.

=head1 ATTRIBUTES

=over 4

=item enable_404_handler

If the C<enable_404_handler> attribute is false, we'll return a 404 status code
from here, and plain "not found" message. The default is true, so that unknown URIs are passed
on to your application.

=item mime_types

A hash reference to map file extensions to MIME types to use. If no MIME type is
found in this hash, a type of 'text/plain' will used. Here are the built-in MIME type mappings.
If the C<mime_types> attribute is used, the new mappings will be merged into the the default mappings,
rather than completely replacing them.

        jpg   => 'image/jpeg',
        jpeg  => 'image/jpeg',
        png   => 'image/png',
        mp3   => 'audio/mpeg',
        '3g2' => 'video/3gpp2',
        '3gp' => 'video/3gpp',
        flv   => 'video/x-flv',
        html  => 'text/html',
        htm   => 'text/html',
        css   => 'text/css',
        csv   => 'text/csv',
        bmp   => 'image/x-bmp',
        ico   => 'image/vnd.microsoft.icon',
        svg   => 'image/svg+xml',
        gif   => 'image/gif',
        gz    => 'application/x-gzip',

=item rules

    Plack::Middleware::Static->new(
        rules => [
            {
                path => qr{^/static/},
                root => './htdocs/',
            }
        ],
    );

An array reference to declare rules for how we serve static content. Each rule is checked in order.
For the first C<path> that matches, we attempt to serve the a static file out of the corresponding
C<root>.

=back

=head1 TODO

This module should also be able to handle "304 Not Modified" responses, but does not currently.
A simple implementation is available in Mojo if you would like to supply a patch:

  http://cpansearch.perl.org/src/KRAIH/Mojo-0.991251/lib/MojoX/Dispatcher/Static.pm

( Search for "304" )

=head1 SEE ALSO

=over 4

=item L<Plack::Middleware> - the parent class

=item L<Plack::Builder> - documentation for declaring which middleware modules to load.

=back

