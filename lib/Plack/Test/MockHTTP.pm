package Plack::Test::MockHTTP;
use strict;
use warnings;

use Carp;
use HTTP::Request;
use HTTP::Response;
use HTTP::Message::PSGI;
use Try::Tiny;

sub new {
    my($class, $app) = @_;
    bless { app => $app }, $class;
}

sub request {
    my($self, $req) = @_;

    $req->uri->scheme('http')    unless defined $req->uri->scheme;
    $req->uri->host('localhost') unless defined $req->uri->host;
    my $env = $req->to_psgi;

    my $res = try {
        HTTP::Response->from_psgi($self->{app}->($env));
    } catch {
        HTTP::Response->from_psgi([ 500, [ 'Content-Type' => 'text/plain' ], [ $_ ] ]);
    };

    $res->request($req);
    return $res;
}

1;

__END__

=head1 NAME

Plack::Test::MockHTTP - Run mocked HTTP tests through PSGI applications

=head1 DESCRIPTION

Plack::Test::MockHTTP is a utility to run PSGI application given
HTTP::Request objects and return HTTP::Response object out of PSGI
application response. See L<Plack::Test> how to use this module.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Test>

=cut


