use strict;
use Plack::Test;
use HTTP::Request;
use Test::More;
use Plack::Middleware::Dechunk;

my @backends = qw(Server MockHTTP); # Server should come first
sub flip_backend { $Plack::Test::Impl = shift @backends }

my $app = sub {
    my $env = shift;
    my $body;
    my $clen = $env->{CONTENT_LENGTH};
    while ($clen > 0) {
        $env->{'psgi.input'}->read(my $buf, $clen) or last;
        $clen -= length $buf;
        $body .= $buf;
    }
    return [ 200, [ 'Content-Type', 'text/plain', 'X-Content-Length', $env->{CONTENT_LENGTH} ], [ $body ] ];
};

$app = Plack::Middleware::Dechunk->wrap($app);

test_psgi $app, sub {
    my $cb = shift;

    my @chunks = ('0123456789') x 4;
    my $content    = join '', @chunks;

    my $req = HTTP::Request->new(POST => "http://localhost/");
    $req->content(sub { shift @chunks });

    my $res = $cb->($req);

    is $res->header('X-Content-Length'), 40;
    is $res->content, $content;
} while flip_backend;

done_testing;
