package Plack::Response;
use strict;
use warnings;
our $VERSION = '0.01';
use base qw/Class::Accessor::Fast/;
use Scalar::Util ();
use CGI::Simple::Cookie ();
use HTTP::Headers;

__PACKAGE__->mk_accessors(qw/body status/);
sub code   { shift->status(@_) } # alias
sub headers {
    my $self = shift;
    $self->{headers} ||= HTTP::Headers->new();
}
sub cookies {
    my $self = shift;
    $self->{cookies} ||= +{ };
}
sub header { shift->headers->header(@_) } # shortcut

sub finalize {
    my $self = shift;
    die "missing status" unless $self->status();

    $self->_finalize_cookies();

    return [
        $self->status,
        +[
            map {
                my $k = $_;
                map { ( $k => $_ ) } $self->headers->header($_);
            } $self->headers->header_field_names
        ],
        $self->body,
    ];
}

sub _finalize_cookies {
    my ( $self ) = @_;

    my $cookies = $self->cookies;
    my @keys    = keys %$cookies;
    if (@keys) {
        for my $name (@keys) {
            my $val    = $cookies->{$name};
            my $cookie = (
                Scalar::Util::blessed($val)
                ? $val
                : CGI::Simple::Cookie->new(
                    -name    => $name,
                    -value   => $val->{value},
                    -expires => $val->{expires},
                    -domain  => $val->{domain},
                    -path    => $val->{path},
                    -secure  => ( $val->{secure} || 0 )
                )
            );

            $self->headers->push_header( 'Set-Cookie' => $cookie->as_string );
        }
    }
}

1;
__END__

=head1 NAME

Plack::Response - Portable HTTP Response object for PSGI response

=head1 SYNOPSIS

  use Plack::Response;

  sub psgi_handler {
      my $env = shift;

      my $res = Plack::Response->new;
      $res->code(200);
      $res->header('Content-Type' => 'text/html');
      $res->body("Hello World");

      return $res->finalize;
  }

=head1 DESCRIPTION

Plack::Response allows you a way to create PSGI response array ref through a simple API.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<Plack::Request>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
