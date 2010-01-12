package Plack::Middleware::Dechunk;
use strict;
no warnings;
use parent qw(Plack::Middleware);

use constant CHUNK_SIZE => 1024;# * 32;

sub call {
    my($self, $env) = @_;

    if (   $env->{HTTP_TRANSFER_ENCODING} eq 'chunked'
        && ($env->{REQUEST_METHOD} eq 'POST' || $env->{REQUEST_METHOD} eq 'PUT')) {
        $self->dechunk_input($env);
    }

    $self->app->($env);
}

sub dechunk_input {
    my($self, $env) = @_;

    my $chunk_buffer = '';
    my($body, $length);

 DECHUNK:
    while (1) {
        my $read = $env->{'psgi.input'}->read($chunk_buffer, CHUNK_SIZE, length $chunk_buffer);

        while ( $chunk_buffer =~ s/^([0-9a-fA-F]+).*\015\012// ) {
            my $chunk_len = hex $1;
            last DECHUNK if $chunk_len == 0;

            $body .= substr $chunk_buffer, 0, $chunk_len, '';
            $chunk_buffer =~ s/^\015\012//;

            $length += $chunk_len;
        }

        last unless $read && $read > 0;
    }

    delete $env->{HTTP_TRANSFER_ENCODING};
    $env->{CONTENT_LENGTH} = $length;
    $env->{'psgi.input'}   = do { open my $input, "<", \$body; $input };
}

1;

__END__

=head1 NAME

Plack::Middleware::Dechunk - Decode chunked (TE: chunked) request body

=head1 SYNOPSIS

  # This should be used in Servers as a library

=head1 DESCRIPTION

This middleware checks if an incoming request is chunked, and in that
case decodes the request body and buffers the whole output, and sets
the IO (either with PerlIO or with a temp filehandle) to
C<psgi.input>. It also sets I<Content-Length> header so your
application can work transparently.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Body>

=cut
