package Plack::Impl::ServerSimple;
use strict;
use warnings;
use base qw/HTTP::Server::Simple::CGI/;
use IO::Handle;
use HTTP::Server::Simple;
use Plack::Impl::CGI;
use Plack::Util;

sub print_banner { }

sub handler {
    my ($self) = @_;
    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT|SERVER_PROTOCOL|CONTENT_LENGTH|CONTENT_TYPE|REMOTE_ADDR)$|^HTTP_/;
        $env{$k} = $v;
    }
    $env{'CONTENT_LENGTH'} = $ENV{CONTENT_LENGTH};
    $env{'CONTENT_TYPE'}   = $ENV{CONTENT_TYPE};
    $env{'HTTP_COOKIE'}  ||= $ENV{COOKIE};
    $env{'SCRIPT_NAME'}    = '';
    $env{'psgi.version'  } = [1,0];
    $env{'psgi.url_scheme'} = 'http';
    $env{'psgi.input'}  = $self->stdin_handle;
    $env{'psgi.errors'} = *STDERR;
    my $res = $self->{__psgi_app}->(\%env);
    print "HTTP/1.0 $res->[0]\r\n";
    my $headers = $res->[1];
    while (my ($k, $v) = splice(@$headers, 0, 2)) {
        print "$k: $v\r\n";
    }
    print "\r\n";

    my $body = $res->[2];
    my $cb = sub { print $_[0] };
    Plack::Util::foreach($body, $cb);
}

sub psgi_app {
    my($self, $app) = @_;
    $self->{__psgi_app} = $app;
}

1;

__END__

=head1 SYNOPSIS

    use Plack::Impl::ServerSimple;

    my $server = Plack::Impl::ServerSimple->new(8080);
    $server->psgi_app(sub {
        my $env = shift;
        return [
            200,
            { 'Content-Type' => 'text/plain', 'Content-Length' => 13 },
            'Hello, world!',
        ];
    });
    $server->run;

=head1 METHODS

=over 4

=item Plack::Impl::ServerSimple->run($code)

Run the app on ServerSimple with PSGI spec.

=back
