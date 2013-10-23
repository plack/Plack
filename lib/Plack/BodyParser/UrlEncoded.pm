package Plack::BodyParser::UrlEncoded;
use strict;
use warnings;
use utf8;
use 5.010_001;
use URL::Encode;
use Hash::MultiValue;

sub new {
    my $class = shift;
    bless { buffer => '' }, $class;
}

sub add {
    my $self = shift;
    if (defined $_[0]) {
        $self->{buffer} .= $_[0];
    }
}

sub finalize {
    my $self = shift;

    my $p = URL::Encode::url_params_flat($self->{buffer});
    return (Hash::MultiValue->new(@$p), Hash::MultiValue->new());
}

1;
__END__

=head1 NAME

Plack::BodyParser::UrlEncoded - application/x-www-form-urlencoded

=head1 SYNOPSIS

    use Plack::Request;
    use Plack::BodyParser;
    use Plack::BodyParser::UrlEncoded;

    my $req = Plack::Request->new(
        $env,
        parse_request_body => sub {
            my $self = shift;
            if ($self->env->{CONTENT_TYPE} =~ m{\Aapplication/x-www-form-urlencoded}) {
                my $parser = Plack::BodyParser::UrlEncoded->new();
                Plack::BodyParser->parse($self->env, $parser);
            }
        }
    );

=head1 DESCRIPTION

This is a HTTP body parser class for application/x-www-form-urlencoded.

