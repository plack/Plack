package Plack::Handler::CGI;
use strict;
use warnings;
use IO::Handle;

# copied from HTTP::Status
my %StatusCode = (
    100 => 'Continue',
    101 => 'Switching Protocols',
    102 => 'Processing',                      # RFC 2518 (WebDAV)
    200 => 'OK',
    201 => 'Created',
    202 => 'Accepted',
    203 => 'Non-Authoritative Information',
    204 => 'No Content',
    205 => 'Reset Content',
    206 => 'Partial Content',
    207 => 'Multi-Status',                    # RFC 2518 (WebDAV)
    300 => 'Multiple Choices',
    301 => 'Moved Permanently',
    302 => 'Found',
    303 => 'See Other',
    304 => 'Not Modified',
    305 => 'Use Proxy',
    307 => 'Temporary Redirect',
    400 => 'Bad Request',
    401 => 'Unauthorized',
    402 => 'Payment Required',
    403 => 'Forbidden',
    404 => 'Not Found',
    405 => 'Method Not Allowed',
    406 => 'Not Acceptable',
    407 => 'Proxy Authentication Required',
    408 => 'Request Timeout',
    409 => 'Conflict',
    410 => 'Gone',
    411 => 'Length Required',
    412 => 'Precondition Failed',
    413 => 'Request Entity Too Large',
    414 => 'Request-URI Too Large',
    415 => 'Unsupported Media Type',
    416 => 'Request Range Not Satisfiable',
    417 => 'Expectation Failed',
    422 => 'Unprocessable Entity',            # RFC 2518 (WebDAV)
    423 => 'Locked',                          # RFC 2518 (WebDAV)
    424 => 'Failed Dependency',               # RFC 2518 (WebDAV)
    425 => 'No code',                         # WebDAV Advanced Collections
    426 => 'Upgrade Required',                # RFC 2817
    449 => 'Retry with',                      # unofficial Microsoft
    500 => 'Internal Server Error',
    501 => 'Not Implemented',
    502 => 'Bad Gateway',
    503 => 'Service Unavailable',
    504 => 'Gateway Timeout',
    505 => 'HTTP Version Not Supported',
    506 => 'Variant Also Negotiates',         # RFC 2295
    507 => 'Insufficient Storage',            # RFC 2518 (WebDAV)
    509 => 'Bandwidth Limit Exceeded',        # unofficial
    510 => 'Not Extended',                    # RFC 2774
);

sub new { bless {}, shift }

sub run {
    my ($self, $app) = @_;

    my $env = $self->setup_env();

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

sub setup_env {
    my ( $self, $override_env ) = @_;

    $override_env ||= {};

    binmode STDIN;
    binmode STDERR;

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
        %{ $override_env },
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

    return $env;
}



sub _handle_response {
    my ($self, $res) = @_;

    *STDOUT->autoflush(1);
    binmode STDOUT;

    my $hdrs;
    my $message = $StatusCode{$res->[0]};
    $hdrs = "Status: $res->[0] $message\015\012";

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

=head1 UTILITY METHODS

=head2 setup_env()

  my $env = Plack::Handler::CGI->setup_env();
  my $env = Plack::Handler::CGI->setup_env(\%override_env);

Sets up the PSGI environment hash for a CGI request from C<< %ENV >>> and returns it.
You can provide a hashref of key/value pairs to override the defaults if you would like.

=head1 SEE ALSO

L<Plack>

=cut


