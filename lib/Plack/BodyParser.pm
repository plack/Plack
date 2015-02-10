package Plack::BodyParser;
use strict;
use warnings;
use utf8;
use 5.008_001;
use Hash::MultiValue;
use Stream::Buffered;

use Plack::BodyParser::OctetStream;

sub new {
    my $class = shift;
    bless { handlers => [] }, $class;
}

sub register {
    my ($self, $content_type, $klass, $opts) = @_;
    push @{$self->{handlers}}, [$content_type, $klass, $opts];
}

sub get_parser {
    my ($self, $env) = @_;

    if (defined $env->{CONTENT_TYPE}) {
        for my $handler (@{$self->{handlers}}) {
            if (index($env->{CONTENT_TYPE}, $handler->[0]) == 0) {
                return $handler->[1]->new($env, $handler->[2]);
            }
        }
    }
    return Plack::BodyParser::OctetStream->new();
}

sub parse {
    my ($self, $env) = @_;

    my $parser = $self->get_parser($env);

    my $ct = $env->{CONTENT_TYPE};
    my $cl = $env->{CONTENT_LENGTH};
    if (!$ct && !$cl) {
        # No Content-Type nor Content-Length -> GET/HEAD
        $env->{'plack.request.body'}   = Hash::MultiValue->new;
        $env->{'plack.request.upload'} = Hash::MultiValue->new;
        return;
    }

    my $input = $env->{'psgi.input'};

    my $buffer;
    if ($env->{'psgix.input.buffered'}) {
        # Just in case if input is read by middleware/apps beforehand
        $input->seek(0, 0);
    } else {
        $buffer = Stream::Buffered->new($cl);
    }

    my $spin = 0;
    while ($cl) {
        $input->read(my $chunk, $cl < 8192 ? $cl : 8192);
        my $read = length $chunk;
        $cl -= $read;
        $parser->add($chunk);
        $buffer->print($chunk) if $buffer;

        if ($read == 0 && $spin++ > 2000) {
            Carp::croak "Bad Content-Length: maybe client disconnect? ($cl bytes remaining)";
        }
    }

    if ($buffer) {
        $env->{'psgix.input.buffered'} = 1;
        $env->{'psgi.input'} = $buffer->rewind;
    } else {
        $input->seek(0, 0);
    }

    ($env->{'plack.request.body'}, $env->{'plack.request.upload'})
        = $parser->finalize();

    return 1;
}


1;
__END__

=head1 NAME

Plack::BodyParser - HTTP request body parser

