use strict;
use warnings;
use Test::More;
use Plack::Response;

sub res {
    my $res = Plack::Response->new;
    my %v = @_;
    while (my($k, $v) = each %v) {
        $res->$k($v);
    }
    $res->finalize;
}

is_deeply(
    res(
        status => 200,
        body => 'hello',
    ),
    [ 200, +[], [ 'hello' ] ]
);
is_deeply(
    res(
        status => 200,
        cookies => +{
            'foo_sid' => +{
                value => 'ASDFJKL:',
                expires => 'Thursday, 25-Apr-1999 00:40:33 GMT',
                domain  => 'example.com',
                path => '/',
            },
            'poo_sid' => +{
                value => 'QWERTYUI',
                expires => 'Thursday, 25-Apr-1999 00:40:33 GMT',
                domain  => 'example.com',
                path => '/',
            },
        },
        body   => 'hello',
    ),
    [
        200,
        +[
            'Set-Cookie' => 'poo_sid=QWERTYUI; domain=example.com; path=/; expires=Thursday, 25-Apr-1999 00:40:33 GMT',
            'Set-Cookie' => 'foo_sid=ASDFJKL%3A; domain=example.com; path=/; expires=Thursday, 25-Apr-1999 00:40:33 GMT',
        ],
        [ 'hello' ],
    ]
);

done_testing;
