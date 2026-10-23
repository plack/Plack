use strict;
use warnings;

use HTTP::Server::PSGI;
use POSIX ();
use Test::More;

{
    package FakeSocket;

    # returns each segment in its own read, at most $len bytes at a time
    sub new {
        my($class, @segments) = @_;
        bless { segments => [ @segments ], out => '' }, $class;
    }

    sub sysread {
        my $self = shift;
        my(undef, $len, $off) = @_;
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

sub run_request {
    my $sock = FakeSocket->new(@_);
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

{
    my($status, $body) = run_request(
        "POST / HTTP/1.0\r\nContent-Length: 5\r\n\r\nab", "c", "de", "GET / HTTP/1.0\r\n\r\n",
    );
    is $status, 200;
    is $body, 'abcde', 'body arriving in short reads is read up to Content-Length';
}

{
    my($status, $body) = run_request(
        "POST / HTTP/1.0\r\nContent-Length: 10\r\n\r\nab", "c",
    );
    is $status, undef, 'no response when the connection closes mid-body';
    is $body, undef, 'app is not called';
}

SKIP: {
    skip 'needs fork', 2 if $^O eq 'MSWin32';
    # Content-Length beyond UV_MAX used to make substr() take all but the
    # last byte of the buffer and then spin forever on the rest
    for my $cl ('18446744073709551616', '9' x 400) {
        my $pid = fork;
        die "fork: $!" unless defined $pid;
        if ($pid == 0) {
            run_request("POST / HTTP/1.0\r\nContent-Length: $cl\r\n\r\nhello");
            POSIX::_exit(0);
        }
        my $done;
        for (1..50) {
            last if $done = waitpid($pid, POSIX::WNOHANG()) == $pid;
            select undef, undef, undef, 0.1;
        }
        unless ($done) {
            kill 'KILL', $pid;
            waitpid $pid, 0;
        }
        ok $done, 'huge Content-Length (' . length($cl) . ' digits) does not loop';
    }
}

for my $cl ('-5', '+5', '5abc', '0x5', '5, 9', '5, 5') {
    my($status, $body) = run_request(
        "POST / HTTP/1.0\r\nContent-Length: $cl\r\n\r\nabcdefghi"
    );
    is $status, 400, "invalid Content-Length '$cl' is rejected";
    is $body, undef, 'app is not called';
}

{
    my($status, $body) = run_request(
        "POST / HTTP/1.0\r\nContent-Length: 5\r\nContent-Length: 9\r\n\r\nabcdefghi"
    );
    is $status, 400, 'duplicate Content-Length headers are rejected';
}

for my $cl ('', "Content-Length: 0\r\n") {
    my($status, $body) = run_request(
        "GET / HTTP/1.0\r\n$cl\r\ntrailing junk"
    );
    is $status, 200;
    is $body, '', 'no body without Content-Length' . ($cl ? ' (0)' : '');
}

for my $te ('chunked', 'gzip, chunked', 'identity') {
    for my $cl ('', "Content-Length: 3\r\n") {
        my($status, $body) = run_request(
            "POST / HTTP/1.1\r\nTransfer-Encoding: $te\r\n$cl\r\n3\r\nabc\r\n0\r\n\r\n"
        );
        is $status, 501, "Transfer-Encoding '$te' is rejected" . ($cl ? ' with Content-Length' : '');
        is $body, undef, 'app is not called';
    }
}

for my $cl ('0', '5', '005') {
    my($status, $body) = run_request(
        "POST / HTTP/1.0\r\nContent-Length: $cl\r\n\r\nabcde"
    );
    is $status, 200, "valid Content-Length '$cl' is accepted";
}

done_testing;
