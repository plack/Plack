use strict;
use warnings;

use HTTP::Server::PSGI;
use Test::More;

{
    package FakeSocket;

    # returns each segment in its own read, at most $len bytes at a time
    sub new {
        my($class, @segments) = @_;
        bless { segments => [ @segments ], reads => [], out => '' }, $class;
    }

    sub sysread {
        my $self = shift;
        my(undef, $len, $off) = @_;
        push @{$self->{reads}}, $len;
        my $seg = \$self->{segments}[0];
        my $chunk = defined $$seg ? substr $$seg, 0, $len, '' : '';
        shift @{$self->{segments}} if defined $$seg && !length $$seg;
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
        "POST / HTTP/1.0\r\nContent-Length: 100000000000\r\n\r\n",
        'x' x (200 * 1024),
    );
    $server->handle_connection({}, $sock, $app);

    my(undef, @body_reads) = @{$sock->{reads}};
    cmp_ok scalar(@body_reads), '>', 1, 'body is read in several reads';
    my($max) = sort { $b <=> $a } @body_reads;
    cmp_ok $max, '<=', HTTP::Server::PSGI::CHUNKSIZE,
        'huge Content-Length does not make a huge sysread';
}

done_testing;
