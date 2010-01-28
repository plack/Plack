package Plack::TempBuffer;
use strict;
use warnings;
use Plack::Util;

our $MaxMemoryBufferSize = 1024 * 1024;

sub new {
    my($class, $length) = @_;

    # $MaxMemoryBufferSize = 0  -> Always temp file
    # $MaxMemoryBufferSize = -1 -> Always PerlIO
    if ($length && $MaxMemoryBufferSize >= 0 && $length > $MaxMemoryBufferSize) {
        Plack::Util::load_class('File', $class)->new($length);
    } else {
        Plack::Util::load_class('PerlIO', $class)->new;
    }
}

sub print;
sub rewind;

1;

__END__

=head1 NAME

Plack::TempBuffer - temporary buffer to save bytes

=head1 SYNOPSIS

  my $buf = Plack::TempBuffer->new($length);
  $buf->print($bytes);
  my $fh = $buf->rewind;

=head1 DESCRIPTION

Plack::TempBuffer is a buffer class to store arbitrary length of byte
strings and then get a seekable filehandle once everything is
buffered. It uses PerlIO and/or temporary file to save the buffer
depending on the length of the size.

=head1 SEE ALSO

L<Plack> L<Plack::Request>

=cut

