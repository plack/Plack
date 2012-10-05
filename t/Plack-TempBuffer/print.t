use strict;
use Test::More;
use Plack::TempBuffer;

my $warn = '';
$SIG{__WARN__} = sub { $warn .= $_[0] };

{
    my $b = Plack::TempBuffer->new(-1);
    $b->print("foo");
    is $b->size, 3;
    my $fh = $b->rewind;
    is do { local $/; <$fh> }, 'foo';
    $fh->seek(0, 0);
}

{
    local $Plack::TempBuffer::MaxMemoryBufferSize = 12;
    my $b = Plack::TempBuffer->new;
    is $b->size, 0;
    $b->print("foo") for 1..5;
    is $b->size, 15;
    my $fh = $b->rewind;
    isa_ok $fh, 'IO::File';
    is do { local $/; <$fh> }, ('foo' x 5);
    like $warn, qr/MaxMemoryBufferSize.*deprecated/;
    $warn = '';
}

{
    local $Plack::TempBuffer::MaxMemoryBufferSize = 0;
    my $b = Plack::TempBuffer->new(3);
    $b->print("foo\n");
    is $b->size, 4;
    my $fh = $b->rewind;
    isa_ok $fh, 'IO::File';
    is do { local $/; <$fh> }, "foo\n";
    like $warn, qr/MaxMemoryBufferSize.*deprecated/;
    $warn = '';
}

done_testing;
