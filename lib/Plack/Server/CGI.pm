package Plack::Server::CGI;
use strict;
use warnings;
use IO::Handle;

sub new { bless {}, shift }

sub run {
    my ($self, $app) = @_;
    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|SCRIPT_NAME|PATH_INFO|QUERY_STRING|SERVER_NAME|SERVER_PORT|SERVER_PROTOCOL|CONTENT_LENGTH|CONTENT_TYPE|REMOTE_ADDR|REQUEST_URI)$|^HTTP_/;
        $env{$k} = $v;
    }
    $env{'HTTP_COOKIE'}   ||= $ENV{COOKIE};
    $env{'psgi.version'}    = [ 1, 0 ];
    $env{'psgi.url_scheme'} = ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http';
    $env{'psgi.input'}      = *STDIN;
    $env{'psgi.errors'}     = *STDERR;
    $env{'psgi.multithread'}  = 1==0;
    $env{'psgi.multiprocess'} = 1==1;
    $env{'psgi.run_once'}     = 1==1;
    my $res = $app->(\%env);
    print "Status: $res->[0]\n";
    my $headers = $res->[1];
    while (my ($k, $v) = splice(@$headers, 0, 2)) {
        print "$k: $v\n";
    }
    print "\n";

    my $body = $res->[2];
    my $cb = sub { print STDOUT $_[0] };

    # inline Plack::Util::foreach here
    if (ref $body eq 'ARRAY') {
        for my $line (@$body) {
            $cb->($line) if length $line;
        }
    } else {
        local $/ = \4096 unless ref $/;
        while (defined(my $line = $body->getline)) {
            $cb->($line) if length $line;
        }
        $body->close;
    }
}

1;
__END__

=head1 SYNOPSIS

    ## in your .cgi
    #!/usr/bin/perl
    use Plack::Server::CGI;

    # or Plack::Util::load_psgi("/path/to/app.psgi");
    my $app = sub {
        my $env = shift;
        return [
            200,
            [ 'Content-Type' => 'text/plain', 'Content-Length' => 13 ],
            [ 'Hello, world!' ],
        ];
    };

    Plack::Server::CGI->new->run($app);

=head1 SEE ALSO

L<Plack::Server::Base>

=cut


