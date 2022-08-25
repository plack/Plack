package Plack::LWPish;
use strict;
use warnings;
use HTTP::Tiny;
use HTTP::Response;
use Hash::MultiValue;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    $self->{http} = @_ == 1 ? $_[0] : HTTP::Tiny->new(verify_SSL => 1, @_);
    $self;
}

sub request {
    my($self, $req) = @_;

    my @headers;
    $req->headers->scan(sub { push @headers, @_ });

    my $options = {
        headers => Hash::MultiValue->new(@headers)->mixed,
    };
    $options->{content} = $req->content if defined $req->content && length($req->content);

    my $response = $self->{http}->request($req->method, $req->url, $options);

    my $res = HTTP::Response->new(
        $response->{status},
        $response->{reason},
        [ Hash::MultiValue->from_mixed($response->{headers})->flatten ],
        $response->{content},
    );
    $res->request($req);

    return $res;
}

1;

__END__

=head1 NAME

Plack::LWPish - HTTP::Request/Response compatible interface with HTTP::Tiny backend

=head1 SYNOPSIS

  use Plack::LWPish;

  my $request = HTTP::Request->new(GET => 'http://perl.com/');

  my $ua = Plack::LWPish->new;
  my $res = $ua->request($request); # returns HTTP::Response

=head1 DESCRIPTION

This module is an adapter object that implements one method,
C<request> that acts like L<LWP::UserAgent>'s request method
i.e. takes HTTP::Request object and returns HTTP::Response object.

This module is used solely inside L<Plack::Test::Suite> and
L<Plack::Test::Server>, and you are recommended to take a look at
L<HTTP::Thin> if you would like to use this outside Plack.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<HTTP::Thin> L<HTTP::Tiny> L<LWP::UserAgent>

=cut
