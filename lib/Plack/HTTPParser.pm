package Plack::HTTPParser;
use strict;
use base qw(Exporter);

our @EXPORT = qw( parse_http_request );

{
    local $@;
    if (eval { require HTTP::Parser::XS; 1 }) {
        *parse_http_request = \&HTTP::Parser::XS::parse_http_request;
    } else {
        require Plack::HTTPParser::PP;
        *parse_http_request = \&Plack::HTTPParser::PP::parse_http_request;
    }
}

1;

__END__

=head1 NAME

Plack::HTTPParser - Parse HTTP headers

=head1 DESCRIPTION

Plack::HTTPParser is a wrapper class to dispatch C<parse_http_request>
to Kazuho Oku's XS based HTTP::Parser::XS or pure perl fallback based
on David Robins HTTP::Parser.

=head1 SEE ALSO

L<HTTP::Parser::XS> L<HTTP::Parser>

=cut
