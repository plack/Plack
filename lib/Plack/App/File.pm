package Plack::App::File;
use strict;
use warnings;
use parent qw/Plack::Component/;
use File::Spec::Unix;
use Cwd ();
use Plack::Util;
use Plack::MIME;
use HTTP::Date;

use Plack::Util::Accessor qw( root file content_type encoding );

sub should_handle {
    my($self, $file) = @_;
    return -f $file;
}

sub call {
    my $self = shift;
    my $env  = shift;

    my($file, $path_info) = $self->file || $self->locate_file($env);
    return $file if ref $file eq 'ARRAY';

    if ($path_info) {
        $env->{'plack.file.SCRIPT_NAME'} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{'plack.file.SCRIPT_NAME'} =~ s/\Q$path_info\E$//;
        $env->{'plack.file.PATH_INFO'}   = $path_info;
    } else {
        $env->{'plack.file.SCRIPT_NAME'} = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
        $env->{'plack.file.PATH_INFO'}   = '';
    }

    return $self->serve_path($env, $file);
}

sub locate_file {
    my($self, $env) = @_;

    my $path = $env->{PATH_INFO} || '';

    if ($path =~ /\0/) {
        return $self->return_400;
    }

    my $docroot = $self->root || ".";
    my @path = split /[\\\/]/, $path, -1; # -1 *MUST* be here to avoid security issues!
    if (@path) {
        shift @path if $path[0] eq '';
    } else {
        @path = ('.');
    }

    if (grep /^\.{2,}$/, @path) {
        return $self->return_403;
    }

    my($file, @path_info);
    while (@path) {
        my $try = File::Spec::Unix->catfile($docroot, @path);
        if ($self->should_handle($try)) {
            $file = $try;
            last;
        } elsif (!$self->allow_path_info) {
            last;
        }
        unshift @path_info, pop @path;
    }

    if (!$file) {
        return $self->return_404;
    }

    if (!-r $file) {
        return $self->return_403;
    }

    return $file, join("/", "", @path_info);
}

sub allow_path_info { 0 }

sub serve_path {
    my($self, $env, $file) = @_;

    my $content_type = $self->content_type || Plack::MIME->mime_type($file)
                       || 'text/plain';

    if ("CODE" eq ref $content_type) {
		$content_type = $content_type->($file);
    }

    if ($content_type =~ m!^text/!) {
        $content_type .= "; charset=" . ($self->encoding || "utf-8");
    }

    open my $fh, "<:raw", $file
        or return $self->return_403;

    my @stat = stat $file;

    Plack::Util::set_io_path($fh, Cwd::realpath($file));

    return [
        200,
        [
            'Content-Type'   => $content_type,
            'Content-Length' => $stat[7],
            'Last-Modified'  => HTTP::Date::time2str( $stat[9] )
        ],
        $fh,
    ];
}

sub return_403 {
    my $self = shift;
    return [403, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['forbidden']];
}

sub return_400 {
    my $self = shift;
    return [400, ['Content-Type' => 'text/plain', 'Content-Length' => 11], ['Bad Request']];
}

# Hint: subclasses can override this to return undef to pass through 404
sub return_404 {
    my $self = shift;
    return [404, ['Content-Type' => 'text/plain', 'Content-Length' => 9], ['not found']];
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
      mount "/favicon.ico" => Plack::App::File->new(file => '/path/to/favicon.ico')->to_app;
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

=item content_type

Set the file content type. If not set L<Plack::MIME> will try to detect it
based on the file extension or fall back to C<text/plain>.
Can be set to a callback which should work on $_[0] to check full path file 
name.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Middleware::Static> L<Plack::App::Directory>

=cut


