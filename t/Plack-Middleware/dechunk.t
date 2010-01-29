use strict;
use Plack::Test;
use HTTP::Request;
use Test::More;
use Digest::MD5;
use Plack::Middleware::Dechunk;

my $file = "share/kyoto.jpg";

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

    open my $fh, "<:raw", $file;
    local $/ = \1024;

    my $req = HTTP::Request->new(POST => "http://localhost/");
    $req->content(sub { scalar <$fh> });

    my $res = $cb->($req);

    is $res->header('X-Content-Length'), 2397701;
    is Digest::MD5::md5_hex($res->content), '9c6d7249a77204a88be72e9b2fe279e8';

} while flip_backend;

done_testing;
