use strict;
use warnings;
use Test::More tests => 1;
use t::Utils;
use Test::Exception;

do {
    throws_ok sub {
        my $data = 'a';
        open my $input, "<", \$data;
        my $req = req(
            env => {
                'psgi.input'   => $input,
                CONTENT_LENGTH => 3,
                CONTENT_TYPE   => 'application/octet-stream'
            },
        );
        $req->_body_parser->http_body();
    } , qr/Wrong Content-Length value: 3/;
#   throws_ok sub {
#       my $data = 'abcde';
#       open my $input, "<", \$data;
#       my $req = req(
#           env => {
#               'psgi.input'   => $input,
#               CONTENT_LENGTH => 3,
#               CONTENT_TYPE   => 'application/octet-stream'
#           },
#       );
#       $req->_body_parser->http_body();
#   } , qr/Premature end of request body, -1 bytes remaining/;
};

