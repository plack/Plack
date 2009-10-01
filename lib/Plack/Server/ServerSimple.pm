package Plack::Server::ServerSimple;
use strict;
use warnings;
use base qw/HTTP::Server::Simple::CGI/;
use IO::Handle;
use HTTP::Server::Simple;
use Plack::Util;
use HTTP::Status;

sub new {
    my($class, %args) = @_;

    my $port = delete $args{port};
    my $host = delete $args{host};

    my $self = $class->SUPER::new($port);
    $self->host($host) if defined $host;

    $self;
}

#sub print_banner { }

sub run {
    my($self, $app) = @_;

    $self->{psgi_app} = $app;
    $self->SUPER::run();
}

sub handler {
    my $self = shift;

    my %env;
    while (my ($k, $v) = each %ENV) {
        next unless $k =~ qr/^(?:REQUEST_METHOD|PATH_INFO|QUERY_STRING|REQUEST_URI|SERVER_NAME|SERVER_PORT|SERVER_PROTOCOL|CONTENT_LENGTH|CONTENT_TYPE|REMOTE_ADDR)$|^HTTP_/;
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
    $env{'psgi.multithread'}  = Plack::Util::FALSE;
    $env{'psgi.multiprocess'} = Plack::Util::FALSE;
    $env{'psgi.run_once'}     = Plack::Util::FALSE;

    my $res = Plack::Util::run_app $self->{psgi_app}, \%env;
    print "HTTP/1.0 $res->[0] @{[ HTTP::Status::status_message($res->[0]) ]}\r\n";
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

    use Plack::Server::ServerSimple;

    my $server = Plack::Server::ServerSimple->new(
        host => $host,
        port => $port,
    );
    $server->run($app);

=cut
