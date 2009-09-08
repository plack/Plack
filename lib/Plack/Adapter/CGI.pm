package Plack::Adapter::CGI;
use strict;
use warnings;
use IO::File;
use HTTP::Status;
use HTTP::Response;
use Carp ();

sub new {
    my($class, $code) = @_;
    bless { code => $code }, $class;
}

sub handler {
    my $self = shift;

    return sub {
        my $env = shift;

        no warnings;
        my $environment = {
            GATEWAY_INTERFACE => 'CGI/1.1',
            # not in RFC 3875
            HTTPS => ( ( $env->{'psgi.url_scheme'} eq 'https' ) ? 'ON' : 'OFF' ),
            SERVER_SOFTWARE => "Plack-Adapter-CGI",
            REMOTE_ADDR     => '127.0.0.1',
            REMOTE_HOST     => 'localhost',
            REMOTE_PORT     => int( rand(64000) + 1000 ),    # not in RFC 3875
            # REQUEST_URI     => $uri->path_query,                 # not in RFC 3875
            ( map { $_ => $env->{$_} } grep !/^psgi\./, keys %$env )
        };

        my $restore = { env => {%ENV} };

        open( $restore->{stdin}, '<&'. STDIN->fileno )
            or Carp::croak("Can't dup stdin: $!");
        *STDIN = $env->{'psgi.input'};

        my $stdout  = IO::File->new_tmpfile;;
        open( $restore->{stdout}, '>&'. STDOUT->fileno )
            or Carp::croak("Can't dup stdout: $!");
        *STDOUT = $stdout;

        open( $restore->{stderr}, '>&'. STDERR->fileno )
            or Carp::croak("Can't dup stderr: $!");
        *STDERR = $env->{'psgi.errors'};

        local *ENV = $environment;

        $self->{code}->();

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

        open( STDIN, '<&' . fileno( $restore->{stdin} ) )
            or Carp::croak("Can't restore stdin: $!");

        open( STDOUT, '>&' . fileno( $restore->{stdout} ) )
            or Carp::croak("Can't restore stdout: $!");

        open( STDERR, '>&' . fileno( $restore->{stderr} ) )
            or Carp::croak("Can't restore stderr: $!");

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

    use Plack::Adapter::CGI;
    my $app = Plack::Adapter::CGI->new(sub { do "/path/to/bar.cgi" })->handler;

=cut


