use strict;
use warnings;
use Test::More tests => 2;
use t::Utils;

# prepare
my $body = 'foo=bar';
open my $in, '<', \$body;

# do test
do {
    my $req = req(
        env => {
            CONTENT_LENGTH => length($body),
            CONTENT_TYPE   => 'application/x-www-form-urlencoded',
            REQUEST_METHOD => 'POST',
            SCRIPT_NAME    => '/',
            'psgi.input'   => $in,
        },
    );
    is $req->raw_body, 'foo=bar';
    is_deeply $req->body_params, { foo => 'bar' };
};

