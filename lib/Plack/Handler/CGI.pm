package Plack::Handler::CGI;
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
    $env{'psgi.streaming'}    = 1==1;
    my $res = $app->(\%env);
    if (ref $res eq 'ARRAY') {
        $self->_handle_response($res);
    }
    elsif (ref $res eq 'CODE') {
        $res->(sub {
            $self->_handle_response($_[0]);
        });
    }
    else {
        die "Bad response $res";
    }
}

sub _handle_response {
    my ($self, $res) = @_;

    *STDOUT->autoflush(1);

    my $hdrs;
    $hdrs = "Status: $res->[0]\015\012";

    my $headers = $res->[1];
    while (my ($k, $v) = splice(@$headers, 0, 2)) {
        $hdrs .= "$k: $v\015\012";
    }
    $hdrs .= "\015\012";

    print STDOUT $hdrs;

    my $body = $res->[2];
    my $cb = sub { print STDOUT $_[0] };

    # inline Plack::Util::foreach here
    if (ref $body eq 'ARRAY') {
        for my $line (@$body) {
            $cb->($line) if length $line;
        }
    }
    elsif (defined $body) {
        local $/ = \65536 unless ref $/;
        while (defined(my $line = $body->getline)) {
            $cb->($line) if length $line;
        }
        $body->close;
    }
    else {
        return Plack::Handler::CGI::Writer->new;
    }
}

package Plack::Handler::CGI::Writer;

sub new {
    return bless \do { my $x }, $_[0];
}

sub write {
    print $_[1];
}

sub close { }

1;
__END__

=head1 SYNOPSIS

Want to run PSGI application as a CGI script? Rename .psgi to .cgi and
change the shebang line like:

  #!/usr/bin/env plackup
  # rest of the file can be the same as other .psgi file

You can alternatively create a file that contains something like:

  #!/usr/bin/perl
  use Plack::Loader;
  my $app = Plack::Util::load_psgi("/path/to/app.psgi");
  Plack::Loader->auto->run($app);

This will auto-recognize the CGI environment variable to load this class.

If you really want to explicitly load the CGI handler, for instance
when you want to embed a PSGI application server built into
CGI-compatible perl based web server:

  use Plack::Handler::CGI;
  Plack::Handler::CGI->new->run($app);

=head1 DESCRIPTION

This is a handler module to run any PSGI application as a CGI script.

=head1 SEE ALSO

L<Plack::Handler>

=cut


