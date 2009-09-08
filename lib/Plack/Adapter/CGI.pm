package Plack::Adapter::CGI;
use strict;
use warnings;
use IO::File;
use HTTP::Status;
use HTTP::Response;
use Carp ();

sub new {
    my ($class, $env) = @_;
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
    my $self = bless {restore => +{ env => +{%ENV} }}, $class;

    open( $self->{restore}->{stdin}, '<&'. STDIN->fileno )
            or Carp::croak("Can't dup stdin: $!");
    *STDIN = $env->{'psgi.input'};

    $self->{stdout} = IO::File->new_tmpfile;;
    open( $self->{restore}->{stdout}, '>&'. STDOUT->fileno )
            or Carp::croak("Can't dup stdout: $!");
    *STDOUT = $self->{stdout};

    open( $self->{restore}->{stderr}, '>&'. STDERR->fileno )
            or Carp::croak("Can't dup stderr: $!");
    *STDERR = $env->{'psgi.errors'};

    {
        no warnings 'uninitialized';
        %ENV = %{ $environment };
    }

    return $self;
}

sub response {
    my ($self) = @_;

    seek( $self->{stdout}, 0, SEEK_SET )
          or croak("Can't seek stdout handle: $!");

    my $headers;
    while ( my $line = $self->{stdout}->getline ) {
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

    my $length = ( stat( $self->{stdout} ) )[7] - tell( $self->{stdout} );
    if ( $response->code == 500 && !$length ) {
        return [
            500,
            [ 'Content-Type' => 'text/html' ],
            [ $response->error_as_HTML ]
        ];
    }

    {
        my $length = 0;
        while ( $self->{stdout}->read( my $buffer, 4096 ) ) {
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
}

sub DESTROY {
    my $self = shift;
    $self->restore();
}

sub restore {
    my $self = shift;
    return unless $self->{restore};

    {
        no warnings 'uninitialized';
        %ENV = %{ $self->{restore}->{env} };
    }

    open( STDIN, '<&' . fileno( $self->{restore}->{stdin} ) )
      or Carp::croak("Can't restore stdin: $!");

    open( STDOUT, '>&' . fileno( $self->{restore}->{stdout} ) )
      or Carp::croak("Can't restore stdout: $!");

    open( STDERR, '>&' . fileno( $self->{restore}->{stderr} ) )
      or Carp::croak("Can't restore stderr: $!");

    delete $self->{restore};
}

1;
__END__

=head1 SYNOPSIS

    use Plack::Adapter::CGI;

    sub handler {
        my $c = Plack::Adapter::CGI->new($env);

        $c->response();
    }

