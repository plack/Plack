use strict;
use warnings;

use HTTP::Server::PSGI;
use Test::More;

{
    package FakeSocket;

    sub new {
        my($class, $data) = @_;
        bless { data => $data, reads => [], out => '' }, $class;
    }

    sub sysread {
        my $self = shift;
        my(undef, $len, $off) = @_;
        push @{$self->{reads}}, $len;
        my $chunk = substr $self->{data}, 0, 1024, '';
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
my $app = sub { [ 200, [ 'Content-Type' => 'text/plain' ], [ 'OK' ] ] };

{
    my $sock = FakeSocket->new(
        "POST / HTTP/1.0\r\nContent-Length: 100000000000\r\n\r\nhello"
    );
    $server->handle_connection({}, $sock, $app);

    my($max) = sort { $b <=> $a } @{$sock->{reads}};
    cmp_ok $max, '<=', HTTP::Server::PSGI::MAX_REQUEST_SIZE,
        'huge Content-Length does not make a huge sysread';
}

done_testing;
