package Plack::HTTPParser::PP;
use strict;
use warnings;
use URI::Escape;

sub parse_http_request {
    my($chunk, $env) = @_;
    $env ||= {};

    # pre-header blank lines are allowed (RFC 2616 4.1)
    $chunk =~ s/^(\x0d?\x0a)+//;
    return -2 unless length $chunk;

    # double line break indicates end of header; parse it
    if ($chunk =~ /^(.*?\x0d?\x0a\x0d?\x0a)/s) {
        return _parse_header($chunk, length $1, $env);
    }
    return -2;  # still waiting for unknown amount of header lines
}

sub _parse_header {
    my($chunk, $eoh, $env) = @_;

    my $header = substr($chunk, 0, $eoh,'');
    $chunk =~ s/^\x0d?\x0a\x0d?\x0a//;

    # parse into lines
    my @header  = split /\x0d?\x0a/,$header;
    my $request = shift @header;

    # join folded lines
    my @out;
    for(@header) {
        if(/^[ \t]+/) {
            return -1 unless @out;
            $out[-1] .= $_;
        } else {
            push @out, $_;
        }
    }

    # parse request or response line
    my $obj;
    my ($major, $minor);

    my ($method,$uri,$http) = split / /,$request;
    return -1 unless $http and $http =~ /^HTTP\/(\d+)\.(\d+)$/i;
    ($major, $minor) = ($1, $2);

    $env->{REQUEST_METHOD}  = $method;
    $env->{SERVER_PROTOCOL} = "HTTP/$major.$minor";
    $env->{REQUEST_URI}     = $uri;

    my($path, $query) = ( $uri =~ /^([^?]*)(?:\?(.*))?$/s );
    for ($path, $query) { s/\#.*$// if defined && length } # dumb clients sending URI fragments

    $env->{PATH_INFO}    = URI::Escape::uri_unescape($path);
    $env->{QUERY_STRING} = $query || '';
    $env->{SCRIPT_NAME}  = '';

    # import headers
    my $token = qr/[^][\x00-\x1f\x7f()<>@,;:\\"\/?={} \t]+/;
    my $k;
    for my $header (@out) {
        if ( $header =~ s/^($token): ?// ) {
            $k = $1;
            $k =~ s/-/_/g;
            $k = uc $k;

            if ($k !~ /^(?:CONTENT_LENGTH|CONTENT_TYPE)$/) {
                $k = "HTTP_$k";
            }
        } elsif ( $header =~ /^\s+/) {
            # multiline header
        } else {
            return -1;
        }

        if (exists $env->{$k}) {
            $env->{$k} .= ", $header";
        } else {
            $env->{$k} = $header;
        }
    }

    return $eoh;
}

1;

__END__

=head1 NAME

Plack::HTTPParser::PP - Pure perl fallback of HTTP::Parser::XS

=head1 DESCRIPTION

Do not use this module directly. Use L<Plack::HTTPParser> instead.

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut

