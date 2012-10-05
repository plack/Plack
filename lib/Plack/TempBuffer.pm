package Plack::TempBuffer;
use strict;
use warnings;

use parent 'Stream::Buffered';

sub new {
    my $class = shift;

    if (defined $Plack::TempBuffer::MaxMemoryBufferSize) {
        warn "Setting \$Plack::TempBuffer::MaxMemoryBufferSize is deprecated. "
           . "You should set \$Stream::Buffered::MaxMemoryBufferSize instead.";
        $Stream::Buffered::MaxMemoryBufferSize = $Plack::TempBuffer::MaxMemoryBufferSize;
    }

    return $class->SUPER::new(@_);
}

1;
