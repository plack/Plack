package Plack::Handler::CGI;
use strict;
use warnings;
use IO::Handle;

sub new { bless {}, shift }

sub run {
    my ($self, $app) = @_;

    my $env = {
        %ENV,
        'psgi.version'    => [ 1, 1 ],
        'psgi.url_scheme' => ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'      => *STDIN,
        'psgi.errors'     => *STDERR,
        'psgi.multithread'  => 0,
        'psgi.multiprocess' => 1,
        'psgi.run_once'     => 1,
        'psgi.streaming'    => 1,
        'psgi.nonblocking'  => 1,
    };

    delete $env->{HTTP_CONTENT_TYPE};
    delete $env->{HTTP_CONTENT_LENGTH};
    $env->{'HTTP_COOKIE'} ||= $ENV{COOKIE}; # O'Reilly server bug

    if (!exists $env->{PATH_INFO}) {
        $env->{PATH_INFO} = '';
    }

    if ($env->{SCRIPT_NAME} eq '/') {
        $env->{SCRIPT_NAME} = '';
        $env->{PATH_INFO}   = '/' . $env->{PATH_INFO};
    }

    my $res = $app->($env);
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
sub new   { bless \do { my $x }, $_[0] }
sub write { print STDOUT $_[1] }
sub close { }

package Plack::Handler::CGI;

1;
__END__

=head1 NAME

Plack::Handler::CGI - CGI handler for Plack

=head1 SYNOPSIS

Want to run PSGI application as a CGI script? Rename .psgi to .cgi and
change the shebang line like:

  #!/usr/bin/env plackup
  # rest of the file can be the same as other .psgi file

You can alternatively create a .cgi file that contains something like:

  #!/usr/bin/perl
  use Plack::Loader;
  my $app = Plack::Util::load_psgi("/path/to/app.psgi");
  Plack::Loader->auto->run($app);

This will auto-recognize the CGI environment variable to load this class.

If you really want to explicitly load the CGI handler, you can. For instance
you might do this when you want to embed a PSGI application server built into
CGI-compatible perl-based web server:

  use Plack::Handler::CGI;
  Plack::Handler::CGI->new->run($app);

=head1 DESCRIPTION

This is a handler module to run any PSGI application as a CGI script.

=head1 SEE ALSO

L<Plack>

=cut


