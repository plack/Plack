use strict;
use warnings;
use Test::More tests => 2;
use t::Utils;

test_req( gen_request() );

sub gen_request {
    my $body = 'foo=bar';
    open my $in,'<',\$body;
    my $req = req(
        env => {
            REQUEST_METHOD   => 'POST',
            CONTENT_LENGTH   => 7,
            CONTENT_TYPE     => 'application/octet-stream',
            'psgi.input'     => $in,
        },
        uri      => do {
            URI::WithBase->new( '/foo', URI->new('foo/') );
        },
    );
    $req;
}

sub test_req {
    my $req = shift;
    my $request = $req->as_string;
    $request =~ s{\nHttps?-Proxy:[^\n]+}{}sg;
    isa_ok $req, 'Plack::Request';
    is $request, "POST /foo
Content-Length: 7
Content-Type: application/octet-stream

foo=bar
";
}
