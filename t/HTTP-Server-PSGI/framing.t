use strict;
use warnings;

use HTTP::Server::PSGI;
use Test::More;

{
    package FakeSocket;

    sub new {
        my($class, $data) = @_;
        bless { data => $data, out => '' }, $class;
    }

    sub sysread {
        my $self = shift;
        my(undef, $len, $off) = @_;
        my $chunk = substr $self->{data}, 0, $len, '';
        $_[0] = '' unless defined $_[0];
        substr($_[0], $off || 0) = $chunk;
        return length $chunk;
    }

    sub syswrite {
        my($self, $buf, $len, $off) = @_;
        $self->{out} .= substr $buf, $off || 0, $len;
        return $len;
    }
}

my $server = HTTP::Server::PSGI->new(timeout => 5);

sub run_request {
    my $req = shift;
    my $sock = FakeSocket->new($req);
    my $body;
    $server->handle_connection({}, $sock, sub {
        my $env = shift;
        local $/;
        my $input = $env->{'psgi.input'};
        $body = <$input>;
        [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ];
    });
    my($status) = $sock->{out} =~ m{^HTTP/1\.\d (\d+)};
    return ($status, $body);
}

{
    my($status, $body) = run_request(
        "POST / HTTP/1.0\r\nContent-Length: 3\r\n\r\nabcGET /next HTTP/1.0\r\n\r\n"
    );
    is $status, 200;
    is $body, 'abc', 'body stops at Content-Length';
}

done_testing;
