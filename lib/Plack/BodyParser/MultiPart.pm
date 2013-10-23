package Plack::BodyParser::MultiPart;
use strict;
use warnings;
use utf8;
use 5.010_001;
use HTTP::MultiPartParser;
use HTTP::Headers::Util    qw[split_header_words];
use File::Temp;
use Hash::MultiValue;
use Carp ();
use Plack::Request::Upload;

sub new {
    my ($class, $env, $opts) = @_;

    my $self = bless { }, $class;

    my $uploads = Hash::MultiValue->new();
    my $params  = Hash::MultiValue->new();

    unless (defined $env->{CONTENT_TYPE}) {
        Carp::croak("Missing CONTENT_TYPE in PSGI env");
    }
    unless ( $env->{CONTENT_TYPE} =~ /boundary=\"?([^\";]+)\"?/ ) {
        Carp::croak("Invalid boundary in content_type: $env->{CONTENT_TYPE}");
    }
    my $boundary = $1;

    my $part;
    my $parser = HTTP::MultiPartParser->new(
        boundary => $boundary,
        on_header => sub {
            my ($headers) = @_;

            my $disposition;
            foreach (@$headers) {
                if (/\A Content-Disposition: [\x09\x20]* (.*)/xi) {
                    $disposition = $1;
                    last;
                }
            }

            (defined $disposition)
                or die q/Content-Disposition header is missing in part/;

            my ($p) = split_header_words($disposition);

            ($p->[0] eq 'form-data')
            or die q/Disposition type is not form-data/;

            my ($name, $filename);
            for(my $i = 2; $i < @$p; $i += 2) {
                if    ($p->[$i] eq 'name')     { $name     = $p->[$i + 1] }
                elsif ($p->[$i] eq 'filename') { $filename = $p->[$i + 1] }
            }

            (defined $name)
                or die q/Parameter 'name' is missing from Content-Disposition header/;

            $part = {
                name    => $name,
                headers => $headers,
            };

            if (defined $filename) {
                $part->{filename} = $filename;

                if (length $filename) {
                    my $fh = File::Temp->new(UNLINK => 1);
                    $part->{fh}       = $fh;
                    $part->{tempname} = $fh->filename;

                    # Save temporary files to $env.
                    # Temporary files will remove after the request.
                    push @{$env->{'plack.bodyparser.multipart.filehandles'}}, $part->{fh};
                }
            }
        },
        on_body => sub {
            my ($chunk, $final) = @_;

            my $fh = $part->{fh};

            if ($fh) {
                print $fh $chunk
                    or die qq/Could not write to file handle: '$!'/;
                if ($final) {
                    seek($fh, 0, SEEK_SET)
                        or die qq/Could not rewind file handle: '$!'/;
                    # TODO: parse headers.
                    $uploads->add($part->{name}, Plack::Request::Upload->new(
                        headers  => $part->{headers},
                        size     => -s $part->{fh},
                        filename => $part->{filename},
                        tempname => $part->{tempname},
                    ));
                }
            } else {
                $part->{data} .= $chunk;
                if ($final) {
                    $params->add($part->{name}, $part->{data});
                }
            }
        },
        $opts->{on_error} ? (on_error => $opts->{on_error}) : (),
    );

    $self->{parser}  = $parser;
    $self->{params}  = $params;
    $self->{uploads} = $uploads;

    return $self;
}

sub add {
    my $self = shift;
    $self->{parser}->parse($_[0]) if defined $_[0];
}

sub finalize {
    my $self = shift;
    $self->{parser}->finish();

    return ($self->{params}, $self->{uploads});
}

1;

