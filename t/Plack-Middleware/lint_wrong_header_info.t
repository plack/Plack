use strict;
use Plack::Test;
use Test::More;
use HTTP::Request::Common;

use Plack::Builder;
use Plack::Middleware::Lint;

my @CASES = (
    {
        app => sub { return [ 200, [ foo => "bar" ], [ 'OK' ] ]; },
        die => undef,
    },
    {
        app => sub { return [ 200, [ foo => undef ], [ 'OK' ] ]; },
        die => qr/Response headers MUST be a defined string. Header: foo/,
    },
    {
        app => sub { return [ 200, [ "foo\nbar" => "baz" ], [ 'OK' ] ]; },
        die => qr/Response headers MUST NOT contain a key with.+Header: foo\nbar/,
    },
    {
        app => sub { return [ 200, [ foo => "\021bar" ], [ 'OK' ] ]; },
        die => qr/Response headers MUST NOT contain characters below octal.+Header: foo/,
    },
    {
        app => sub { return [ 200, [ "foo\021" => "bar" ], [ 'OK' ] ]; },
        die => qr/Response headers MUST consist only of letters, digits, _ or.+Header: foo\021/,
    },
);

for my $case ( @CASES ) {
    my $linted_app = Plack::Middleware::Lint->wrap( $case->{app} );
    my $die_reason = $case->{die};
    test_psgi $linted_app, sub {
        my $cb = shift;
        my $res = $cb->(GET "/");
        if ( $die_reason ) {
            is $res->code, 500, "Code of ". $res->content;
            like $res->content, $die_reason, "Text of ". $res->content;
        }
        else {
            is $res->code, 200, $res->content;
        }
    };
}

done_testing;
