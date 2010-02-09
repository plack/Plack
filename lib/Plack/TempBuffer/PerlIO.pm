package Plack::TempBuffer::PerlIO;
use strict;
use parent 'Plack::TempBuffer';

sub new {
    my $class = shift;
    bless { buffer => '' }, $class;
}

sub print {
    my $self = shift;
    $self->{buffer} .= "@_";
}

sub size {
    my $self = shift;
    length $self->{buffer};
}

sub rewind {
    my $self = shift;
    my $buffer = $self->{buffer};
    open my $io, "<", \$buffer;
    bless $io, 'FileHandle'; # This makes $io work as FileHandle under 5.8, .10 and .11 :/
    return $io;
}

1;
