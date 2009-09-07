use strict;
use warnings;
use Test::More tests => 2;

use t::Utils;

my $body = 'body';
open my $in, '<', \$body;
my $req = req(
    env => {
        'psgi.input'   => $in,
        CONTENT_LENGTH => 4,
        CONTENT_TYPE   => 'application/octet-stream'
    }
);
is $req->content, 'body';

eval {
    $req->content('content');
};
like $@, qr/^The HTTP::Request method 'content'/;
