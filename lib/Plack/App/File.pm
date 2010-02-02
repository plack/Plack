package Plack::App::File;
use strict;
use warnings;
use parent qw/Plack::Component/;
use File::Spec::Unix;
use Path::Class 'dir';
use Plack::Util;
use Plack::MIME;
use HTTP::Date;

use Plack::Util::Accessor qw( root file encoding );

sub should_handle {
    my($self, $file) = @_;
    return -f $file;
}

sub call {
    my $self = shift;
    my $env  = shift;

    my $file = $self->file || $self->locate_file($env);
    return $file if ref $file eq 'ARRAY';

    return $self->serve_path($env, $file);
}

sub locate_file {
    my($self, $env) = @_;

    my $path = $env->{PATH_INFO};
    if ($path =~ m!\.\.[/\\]!) {
        return $self->return_403;
    }

    my $docroot = dir($self->root || ".");
    my $file = $docroot->file(File::Spec::Unix->splitpath($path))->absolute;

    # Is the requested path within the root?
    if (!$docroot->subsumes($file)) {
        return $self->return_403;
    }

    # Does the file actually exist?
    if (!$self->should_handle($file)) {
        return $self->return_404;
    }

    # If the requested file present but lacking the permission to read it?
    if (!-r $file) {
        return $self->return_403;
    }

    return $file;
}


sub serve_path {
    my($self, $env, $file) = @_;

    $file = Path::Class::File->new($file)
        unless ref $file;

    my $content_type = Plack::MIME->mime_type($file) || 'text/plain';

    if ($content_type =~ m!^text/!) {
        $content_type .= "; charset=" . ($self->encoding || "utf-8");
    }

    my $fh = $file->openr
        or return $self->return_403;

    my $path = $file->stringify;
       $path =~ s!\\!/!g;
    Plack::Util::set_io_path($fh, $path);
    binmode $fh;

    my $stat = $file->stat;
    return [
        200,
        [
            'Content-Type'   => $content_type,
            'Content-Length' => $stat->size,
            'Last-Modified'  => HTTP::Date::time2str( $stat->mtime )
        ],
        $fh,
    ];
}

sub return_403 {
    my $self = shift;
    return [403, ['Content-Type' => 'text/plain'], ['forbidden']];
}

# Hint: subclasses can override this to return undef to pass through 404
sub return_404 {
    my $self = shift;
    return [404, ['Content-Type' => 'text/plain'], ['not found']];
}

1;
__END__

=head1 NAME

Plack::App::File - Serve static files from root directory

=head1 SYNOPSIS

  use Plack::App::File;
  my $app = Plack::App::File->new(root => "/path/to/htdocs")->to_app;

  # Or map the path to a specific file
  use Plack::Builder;
  builder {
      mount "/favicon.ico" => Plack::App::File->new(file => '/path/to/favicon.ico');
  };

=head1 DESCRIPTION

This is a static file server PSGI application, and internally used by
L<Plack::Middleware::Static>. This application serves file from
document root if the path matches with the local file. Use
L<Plack::App::Directory> if you want to list files in the directory
as well.

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to C<.> (current directory)

=item file

The file path to create responses from. Optional.

If it's set the application would B<ALWAYS> create a response out of
the file and there will be no security check etc. (hence fast). If
it's not set, the application uses C<root> to find the matching file.

=item encoding

Set the file encoding for text files. Defaults to C<utf-8>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Middleware::Static> L<Plack::App::Directory>

=cut


