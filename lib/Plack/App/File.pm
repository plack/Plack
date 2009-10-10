package Plack::App::File;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use File::Spec::Unix;
use Path::Class 'dir';
use Plack::Util;
use HTTP::Date;
use MIME::Types;
use Cwd ();

__PACKAGE__->mk_accessors(qw( root ));

sub call {
    my $self = shift;
    my $env  = shift;

    my $path = $env->{PATH_INFO};
    if ($path =~ m!\.\.[/\\]!) {
        return $self->return_403;
    }

    my $docroot = dir($self->root || ".");
    my $file = $docroot->file(File::Spec::Unix->splitpath($path));
    my $realpath = Cwd::realpath($file->absolute->stringify);

    # Is the requested path within the root?
    if ($realpath && !$docroot->subsumes($realpath)) {
        return $self->return_403;
    }

    # Does the file actually exist?
    if (!$realpath || !-f $file) {
        return $self->return_404;
    }

    # If the requested file present but lacking the permission to read it?
    if (!-r $file) {
        return $self->return_403;
    }

    my $content_type = do {
        my $type;
        if ($file =~ /.*\.(\S{1,})$/xms ) {
            $type = (MIME::Types::by_suffix $1)[0];
        }
        $type ||= 'text/plain';
    };

    my $fh = $file->openr
        or return $self->return_403;
    Plack::Util::set_io_path($fh, $realpath);
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
  my $app = Plack::App::File->new({ root => "/path/to/htdocs" });

=head1 DESCRIPTION

This is a static file server PSGI application, and internally used by L<Plack::Middleware::Static>.

=head1 CONFIGURATION

=over 4

=item root

Document root directory.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Middleware::Static>

=cut


