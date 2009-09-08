package Plack::Impl::FCGI::EV::Handler;

use strict;
use Plack::Util;
use base qw(Class::Data::Inheritable);
__PACKAGE__->mk_classdata('psgi_app');
    
use Data::Dumper;

sub new {
    my $class = shift;
    my ($server, $ENV) = @_;
    my $env = {
        SCRIPT_NAME       => '',
        'psgi.version'    => [ 1, 0 ],
        'psgi.errors'     => *STDERR,
        'psgi.url_scheme' => 'http',
        %$ENV
    };

    my $request_uri = $env->{REQUEST_URI};
    my ( $file, $query_string ) = ( $request_uri =~ /([^?]*)(?:\?(.*))?/s );    # split at ?
    $env->{PATH_INFO} = $file;
    $env->{QUERY_STRING} = $query_string || '';
    # warn Dumper $env;

    my $self = {
        stdin => '',
        server => $server,
        env => $env
    };
    bless $self, $class;
}

# not support Async Input (too much memory use)
sub stdin {
    my ($self, $stdin, $is_eof) = @_;
    $self->{stdin} .= $stdin;
    if ($is_eof) {
        open my $input, "<", \$self->{stdin};
        $self->{env}->{'psgi.input'} = $input;
        $self->run_app;
    }
}

sub run_app {
    my $self   = shift;
    my $res    = $self->psgi_app->( $self->{env} );
    my $server = $self->{server};

    # header
    my ( $status, $headers, $body ) = @{$res};
    $server->stdout("HTTP/1.0 $status\r\n");
    while ( my ( $k, $v ) = splice( @$headers, 0, 2 ) ) {
        $server->stdout("$k: $v\r\n");
    }
    $server->stdout("\r\n");

    # body
    my $cb = sub { $server->stdout( $_[0] ) };
    Plack::Util::foreach( $body, $cb );

    # close
    $server->stdout( "", 1 );
}

1;
