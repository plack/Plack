package Plack::BodyParser::JSON;
use strict;
use warnings;
use utf8;
use JSON ();
use Encode qw(encode_utf8);
use Hash::MultiValue;

sub new {
    my $class = shift;
    bless {buffer => ''}, $class;
}

sub add {
    my $self = shift;
    $self->{buffer} .= $_[0] if defined $_[0];
}

sub finalize {
    my $self = shift;

    my $p = JSON::decode_json($self->{buffer});
    my $params = Hash::MultiValue->new();
    if (ref $p eq 'HASH') {
        while (my ($k, $v) = each %$p) {
            if (ref $v eq 'ARRAY') {
                for (@$v) {
                    $params->add(encode_utf8($k), encode_utf8($_));
                }
            } else {
                $params->add(encode_utf8($k), encode_utf8($v));
            }
        }
    }
    return ($params, Hash::MultiValue->new());
}

1;

