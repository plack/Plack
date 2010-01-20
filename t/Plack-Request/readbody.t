use strict;
use warnings;
use Test::More tests => 1;
use Plack::Test;
use Plack::Request;
use Try::Tiny;

{
    try {
        my $data = 'a';
        open my $input, "<", \$data;
        my $req = Plack::Request->new({
            'psgi.input'   => $input,
            CONTENT_LENGTH => 3,
            CONTENT_TYPE   => 'application/octet-stream'
        });
        $req->_body_parser->http_body();
    } catch {
        like $_, qr/Wrong Content-Length value: 3/;
    }
}

