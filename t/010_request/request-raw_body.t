use strict;
use warnings;
use Test::More;
use t::Utils;

plan tests => 1;

my $content = "Your base are belongs to us.";

open my $in, '<', \$content;
my $req = req(
    env => {
        CONTENT_LENGTH => length($content),
        CONTENT_TYPE   => 'application/octet-stream',
        REQUEST_METHOD => 'POST',
        'psgi.input'   => $in,
    }
);
is $req->raw_body, $content;

