package Plack::Server::ReverseHTTP;
use strict;
use AnyEvent::ReverseHTTP;
use AnyEvent::Handle;
use AnyEvent::Socket;
use HTTP::Response;
use Plack::Util;

sub new {
    my($class, %args) = @_;
    bless \%args, $class;
}

sub run {
    my($self, $app) = @_;

    $self->{guard} = reverse_http $self->{host}, $self->{token}, sub {
        # TODO: can this be moved to ReverseHTTP?
        my $req = shift;

        # Can this be moved to ::Util and shared?
        my($host, $port) = split /:/, $req->header('Host'), 2;
        my $env = {
            REQUEST_METHOD  => $req->method,
            SCRIPT_NAME     => "",
            PATH_INFO       => $req->uri->path,
            QUERY_STRING    => $req->uri->query,
            SERVER_NAME     => $host,
            SERVER_PORT     => $port || 80,
            SERVER_PROTOCOL => $req->protocol,
            CONTENT_TYPE    => $req->content_type,
            CONTENT_LENGTH  => $req->content_length,
        };

        $req->headers->scan(sub {
            my($k, $v) = @_;
            next if $k eq 'Content-Type' || $k eq 'Content-Length';
            $k =~ tr/-/_/;
            $env->{"HTTP_". uc($k)} = $v;
        });

        open my $input, "<", $req->content;

        $env->{'psgi.version'} = [ 1, 0 ];
        $env->{'psgi.url_scheme'} = 'http';
        $env->{'psgi.input'}      = $input;
        $env->{'psgi.errors'}     = *STDERR;

        $env->{'psgi.nonblocking'}  = Plack::Util::TRUE;
        $env->{'psgi.multithread'}  = Plack::Util::FALSE;
        $env->{'psgi.multiprocess'} = Plack::Util::FALSE;
        $env->{'psgi.run_once'}     = Plack::Util::FALSE;

        my $r = $app->($env);

        my $res = HTTP::Response->new($r->[0]);
        while (my($k, $v) = splice @{$r->[1]}, 0 ,2) {
            $res->push_header($k, $v);
        }

        my $body;
        Plack::Util::foreach($r->[2], sub { $body .= $_[0] });

        $res->content($body);

        return $res;
    };
}

sub run_loop {
    AE::cv->recv;
}

1;

__END__

=head1 NAME

Plack::Server::ReverseHTTP - reversehttp gateway for PSGI application

=head1 SYNOPSIS

  plackup YourApp -i ReverseHTTP \
    host rhttplabel token your-token

=head1 DESCRIPTION

Plack::Server::ReverseHTTP is a PSGI implementation that uses
ReverseHTTP gateway to access your PSGI application on your desktop or
behind the firewall from the internet. Just like Ruby's hookout does
with Rack applications.

=head1 AUTHOR

Tatsuhiko Miyagawa E<lt>miyagawa@bulknews.netE<gt>

=head1 SEE ALSO

L<AnyEvent::ReverseHTTP> L<http://github.com/paulj/hookout/tree/master> L<http://www.reversehttp.net/>

=cut
