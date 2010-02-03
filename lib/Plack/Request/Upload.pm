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

Returns basename for "filename".

=back

=head1 AUTHORS

Kazuhiro Osawa

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Request>, L<Catalyst::Request::Upload>

=cut
