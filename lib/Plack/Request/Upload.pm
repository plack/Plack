package Plack::Request::Upload;
use strict;
use warnings;
BEGIN { require Carp }; # do not call Carp->import for performance

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

sub type { 
    my $self = shift;
    unless ($self->{headers} && $self->{headers}->can('content_type')) {
        Carp::croak 'Cannot delegate type to content_type because the value of headers is not defined';
    }
    $self->{headers}->content_type(@_);
}

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

sub fh {
    my $self = shift;
    unless (defined $self->{fh}) {
        open my $fh, '<', $self->{tempname} or die "Can't open '@{[ $self->tempname ]}': '$!'";
        $self->{fh} = $fh;
    }
    $self->{fh};
}

sub copy_to {
    my $self = shift;
    require File::Copy;
    File::Copy::copy( $self->{tempname}, @_ );
}

sub link_to {
    my ( $self, $target ) = @_;
    CORE::link( $self->{tempname}, $target );
}

sub slurp {
    my ( $self, $layer ) = @_;

    $layer = ':raw' unless $layer;

    my $content = undef;
    my $handle  = $self->fh;

    binmode( $handle, $layer );

    while ( $handle->read( my $buffer, 8192 ) ) {
        $content .= $buffer;
    }

    $content;
}

1;
__END__

=head1 NAME

Plack::Request::Upload - handles file upload requests

=head1 METHODS

=over 4

=item basename

Returns basename for "filename".

=item link_to

Creates a hard link to the temporary file. Returns true for success,
false for failure.

    $upload->link_to('/path/to/target');

=item slurp

Returns a scalar containing the contents of the temporary file.

=item copy_to

Copies the temporary file using File::Copy. Returns true for success,
false for failure.

    $upload->copy_to('/path/to/targe')

=back

=head1 AUTHORS

Kazuhiro Osawa and Plack authors.

=head1 THANKS TO

the authors of L<Catalyst::Request::Upload>.

=head1 SEE ALSO

L<Plack>, L<Catalyst::Request::Upload>

