use strict;
use warnings;
use Test::More tests => 5;

use t::Utils;

test_req( gen_request()->as_http_request );

sub gen_request {
    my $body = 'foo=bar';
    open my $fh, '<', \$body;
    my $req = req(
        env => {
            REQUEST_METHOD => 'POST',
            SERVER_NAME    => 'example.com',
            SERVER_PORT    => 80,
            PATH_INFO      => '/foo',
            QUERY_STRING   => 'p=q',
            CONTENT_LENGTH => 7,
            CONTENT_TYPE   => 'application/octet-stream',
            'psgi.input'   => $fh,
        },
    );
    $req;
}

sub test_req {
    my $req = shift;
    isa_ok $req, 'HTTP::Request';
    is $req->method,  'POST';
    is $req->uri,     'http://example.com/foo?p=q';
    is $req->content, 'foo=bar';
    is $req->header('Content-Type'), 'application/octet-stream';
}

