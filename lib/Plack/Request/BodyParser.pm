package Plack::Request::BodyParser;
use strict;
use warnings;
BEGIN { require Carp }; # do not call Carp->import for performance
use HTTP::Body;

# ABOUT: This is internal class. Do not call directly.

sub new {
    my($class, $env) = @_;

    Carp::confess q{Attribute ($env->{'psgi.input'}) is required}
        unless defined $env->{'psgi.input'};

    bless {
        content_length => $env->{'CONTENT_LENGTH'} || 0,
        content_type   => $env->{'CONTENT_TYPE'}   || '',
        input_handle   => $env->{'psgi.input'},
        _read_position => 0,
        chunk_size     => 4096,
    }, $class;
}

# tempolary file path for upload file.
sub upload_tmp {
    $_[0]->{upload_tmp} = defined $_[1] ? $_[1] : $_[0]->{upload_tmp};
}

sub http_body {
    my ( $self, ) = @_;

    $self->_read_to_end();
    return $self->_http_body;
}

sub raw_body {
    my ( $self, ) = @_;

    $self->_read_to_end();
    return $self->{_raw_body};
}

sub _http_body {
    my($self, ) = @_;
    unless (defined $self->{_http_body}) {
        my $body = HTTP::Body->new($self->{content_type}, $self->{content_length});
        $body->tmpdir( $self->upload_tmp ) if $self->upload_tmp;
        $self->{_http_body} = $body;
    }
    $self->{_http_body};
}

sub _read_position { $_[0]->{_read_position} }

sub input_handle { $_[0]->{input_handle} }

sub _read_to_end {
    my ( $self, ) = @_;

    my $content_length = $self->{content_length};

    if ($content_length > 0) {
        while (my $buffer = $self->_read() ) {
            $self->{_raw_body} .= $buffer;
            $self->_http_body->add($buffer);
        }

        # paranoia against wrong Content-Length header
        my $diff = $content_length - $self->_read_position;

        if ($diff != 0) {
            if ( $diff > 0) {
                die "Wrong Content-Length value: " . $content_length;
            } else {
                die "Premature end of request body, $diff bytes remaining";
            }
        }
    }
}

sub _read {
    my ($self, ) = @_;

    my $remaining = $self->{content_length} - $self->_read_position();

    my $maxlength = $self->{chunk_size};

    # Are we done reading?
    if ($remaining <= 0) {
        return;
    }

    my $readlen = ($remaining > $maxlength) ? $maxlength : $remaining;

    my $rc = $self->input_handle->read(my $buffer, $readlen);

    if (defined $rc) {
        $self->{_read_position} += $rc;
        return $buffer;
    } else {
        die "Unknown error reading input: $!";
    }
}

1;
