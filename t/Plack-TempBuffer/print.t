use strict;
use Test::More;
use Plack::TempBuffer;

{
    my $b = Plack::TempBuffer->new;
    $b->print("foo");
    my $fh = $b->rewind;
    is do { local $/; <$fh> }, 'foo';
}

{
    local $Plack::TempBuffer::MaxMemoryBufferSize = 0;
    my $b = Plack::TempBuffer->new(3);
    $b->print("foo\n");
    my $fh = $b->rewind;
    is do { local $/; <$fh> }, "foo\n";
}

done_testing;
