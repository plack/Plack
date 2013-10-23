package Plack::BodyParser::OctetStream;
use strict;
use warnings;
use utf8;
use 5.008_001;

sub new {
    my $class = shift;
    bless {}, $class;
}

sub add { }

sub finalize {
    return (
        Hash::MultiValue->new(),
        Hash::MultiValue->new()
    );
}

1;

