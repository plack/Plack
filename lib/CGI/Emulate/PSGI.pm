package CGI::Emulate::PSGI;
use strict;
use warnings;
use POSIX 'SEEK_SET';
use HTTP::Response;
use IO::File;

sub handler {
    my ($class, $code, ) = @_;

    return sub {
        my $env = shift;
        no warnings;
        my $environment = {
            GATEWAY_INTERFACE => 'CGI/1.1',
            # not in RFC 3875
            HTTPS => ( ( $env->{'psgi.url_scheme'} eq 'https' ) ? 'ON' : 'OFF' ),
            SERVER_SOFTWARE => "CGI-Emulate-PSGI",
            REMOTE_ADDR     => '127.0.0.1',
            REMOTE_HOST     => 'localhost',
            REMOTE_PORT     => int( rand(64000) + 1000 ),    # not in RFC 3875
            # REQUEST_URI     => $uri->path_query,                 # not in RFC 3875
            ( map { $_ => $env->{$_} } grep !/^psgi\./, keys %$env )
        };

        my $stdout  = IO::File->new_tmpfile;

        {
            local *STDIN  = $env->{'psgi.input'};
            local *STDOUT = $stdout;
            local *STDERR = $env->{'psgi.errors'};
            local *ENV    = $environment;

            $code->();
        }

        seek( $stdout, 0, SEEK_SET )
            or croak("Can't seek stdout handle: $!");

        my $headers;
        while ( my $line = $stdout->getline ) {
            $headers .= $line;
            last if $headers =~ /\x0d?\x0a\x0d?\x0a$/;
        }
        unless ( defined $headers ) {
            $headers = "HTTP/1.1 500 Internal Server Error\x0d\x0a";
        }

        unless ( $headers =~ /^HTTP/ ) {
            $headers = "HTTP/1.1 200 OK\x0d\x0a" . $headers;
        }

        my $response = HTTP::Response->parse($headers);
        $response->date( time() ) unless $response->date;

        my $status = $response->header('Status') || 200;
        $status =~ s/\s+.*$//; # remove ' OK' in '200 OK'

        my $length = ( stat( $stdout ) )[7] - tell( $stdout );
        if ( $response->code == 500 && !$length ) {
            return [
                500,
                [ 'Content-Type' => 'text/html' ],
                [ $response->error_as_HTML ]
            ];
        }

        {
            my $length = 0;
            while ( $stdout->read( my $buffer, 4096 ) ) {
                $length += length($buffer);
                $response->add_content($buffer);
            }

            if ( $length && !$response->content_length ) {
                $response->content_length($length);
            }
        }

        return [
            $status,
            +[
                map {
                    my $k = $_;
                    map { ( $k => $_ ) } $response->headers->header($_);
                } $response->headers->header_field_names
            ],
            [$response->content],
        ];
    };
}

1;
__END__

=head1 SYNOPSIS

    my $app = CGI::Emulate::PSGI->handler(sub {
        # Existent CGI code, or just:
        do "script.cgi";
    });

=head2 DESCRIPTION

This module allows an application designed for the CGI environment to
run in a PSGI environment, and thus on any of the backends that PSGI
supports.

It works by translating the environment provided by the PSGI
specification to one expected by the CGI specification. Likewise, it
captures output as it would be prepared for the CGI standard, and
translates it to the format expected for the PSGI standard.

=head1 CGI.pm

If your application uses L<CGI>, be sure to cleanup the global
variables in the handler loop yourself, so:

    my $app = CGI::Emulate::PSGI->handler(sub {
        do "script-that-uses-cgi-pm.cgi";
        CGI::initialize_globals() if defined &CGI::initialize_globals;
    });

Otherwise previous request variables will be reused in the new
requests.

Alternatively, you can install and use L<CGI::PSGI> from CPAN, but
that would require you to slightly change your code from:

  my $q = CGI->new;
  # ...
  print $q->header, $output;

into:

  use CGI::PSGI;

  my $app = sub {
      my $env = shift;
      my $q = CGI::PSGI->new($env);
      # ...
      return [ $q->psgi_header, [ $output ] ];
  };

See L<CGI::PSGI> for details.

=cut
