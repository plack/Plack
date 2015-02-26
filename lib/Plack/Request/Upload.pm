package Plack::Request::Upload;
use strict;
use warnings;
use Carp ();

sub new {
    my($class, %args) = @_;

    bless {
        headers  => $args{headers},
        tempname => $args{tempname},
        size     => $args{size},
        filename => $args{filename},
    }, $class;
}

sub filename { $_[0]->{filename} }
sub headers  { $_[0]->{headers} }
sub size     { $_[0]->{size} }
sub tempname { $_[0]->{tempname} }
sub path     { $_[0]->{tempname} }

sub content_type {
    my $self = shift;
    $self->{headers}->content_type(@_);
}

sub type { shift->content_type(@_) }

sub basename {
    my $self = shift;
    unless (defined $self->{basename}) {
        require File::Spec::Unix;
        my $basename = $self->{filename};
        $basename =~ s|\\|/|g;
        $basename = ( File::Spec::Unix->splitpath($basename) )[2];
        $basename =~ s|[^\w\.-]+|_|g;
        $self->{basename} = $basename;
    }
    $self->{basename};
}

sub raw_basename {
    my $self = shift;
    unless (defined $self->{raw_basename}) {
        require File::Spec::Unix;
        my $raw_basename = $self->{filename};
        $raw_basename =~ s|\\|/|g;
        $raw_basename = ( File::Spec::Unix->splitpath($raw_basename) )[2];
        $self->{raw_basename} = $raw_basename;
    }
    $self->{raw_basename};
}


1;
__END__

=head1 NAME

Plack::Request::Upload - handles file upload requests

=head1 SYNOPSIS

  # $req is Plack::Request
  my $upload = $req->uploads->{field};

  $upload->size;
  $upload->path;
  $upload->content_type;
  $upload->basename;
  $upload->raw_basename;

=head1 METHODS

=over 4

=item size

Returns the size of Uploaded file.

=item path

Returns the path to the temporary file where uploaded file is saved.

=item content_type

Returns the content type of the uploaded file.

=item filename

Returns the original filename in the client.

=item basename

Returns basename for "filename". This filters the name through a regexp
C<basename =~ s|[^\w\.-]+|_|g> to make it safe for filesystems that don't
like advanced characters.  This will of course filter UTF8 characters.
If you need the exact basename unfiltered use "raw_basename".

=item raw_basename

Just like "basename" but without filtering the filename for characters that
don't always write to a filesystem.

=back

=head1 AUTHORS

Kazuhiro Osawa

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Request>, L<Catalyst::Request::Upload>

=cut
