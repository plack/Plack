package Plack::Server::ReverseHTTP;
use strict;
use AnyEvent::ReverseHTTP;
use HTTP::Message::PSGI;
use HTTP::Response;
use Plack::Util;

sub new {
    my($class, %args) = @_;
    bless \%args, $class;
}

sub run {
    my($self, $app) = @_;
    $self->{guard} = reverse_http $self->{host}, $self->{token}, sub {
        my $req = shift;
        my $env = $req->to_psgi;

        if (my $client = delete $env->{HTTP_REQUESTING_CLIENT}) {
            @{$env}{qw( REMOTE_ADDR REMOTE_PORT )} = split /:/, $client, 2;
        }

        $env->{'psgi.nonblocking'}  = Plack::Util::TRUE;
        $env->{'psgi.multithread'}  = Plack::Util::FALSE;
        $env->{'psgi.multiprocess'} = Plack::Util::FALSE;
        $env->{'psgi.run_once'}     = Plack::Util::FALSE;

        my $r = $app->($env);
        return HTTP::Response->from_psgi($r);
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

  > plackup --server ReverseHTTP --host rhttplabel --token your-token

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
