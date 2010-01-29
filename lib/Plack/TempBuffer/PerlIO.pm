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

sub rewind {
    my $self = shift;
    my $buffer = $self->{buffer};
    open my $io, "<", \$buffer;
    return $io;
}

1;
