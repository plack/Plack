package Plack::HTTPParser;
use strict;
use parent qw(Exporter);

our @EXPORT = qw( parse_http_request );

use Try::Tiny;

{
    if (!$ENV{PLACK_HTTP_PARSER_PP} && try { require HTTP::Parser::XS; 1 }) {
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

=head1 SYNOPSIS

  use Plack::HTTPParser qw(parse_http_request);

  my $ret = parse_http_request($header_str, \%env);
  # see HTTP::Parser::XS docs

=head1 DESCRIPTION

Plack::HTTPParser is a wrapper class to dispatch C<parse_http_request>
to Kazuho Oku's XS based HTTP::Parser::XS or pure perl fallback based
on David Robins HTTP::Parser.

If you want to force the use of the slower pure perl version even if the
fast XS version is available, set the environment variable
C<PLACK_HTTP_PARSER_PP> to 1.

=head1 SEE ALSO

L<HTTP::Parser::XS> L<HTTP::Parser>

=cut
