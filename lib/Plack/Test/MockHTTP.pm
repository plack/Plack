package Plack::Test::MockHTTP;
use strict;
use warnings;

use Carp;
use HTTP::Request;
use HTTP::Response;
use HTTP::Request::AsCGI;
use Plack::Server::CGI;

sub test_psgi {
    my %args = @_;

    my $client = delete $args{client} or croak "client test code needed";
    my $app    = delete $args{app}    or croak "app needed";

    my $cb = sub {
        my $req = shift;
        my $c   = HTTP::Request::AsCGI->new($req)->setup;
        eval { Plack::Server::CGI->new->run($app) };
        return $c->response;
    };

    $client->($cb);
}

1;

__END__

=head1 NAME

Plack::Test::MockHTTP - Run mocked HTTP tests through PSGI applications

=head1 DESCRIPTION

Plack::Test::MockHTTP is an utility to run PSGI application given
HTTP::Request objects and return HTTP::Response object out of PSGI
application response. See L<Plack::Test> how to use this module.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Test>

=cut


