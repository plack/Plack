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

my $res = res(
    status => 200,
    cookies => +{
        'foo_sid' => +{
            value => 'ASDFJKL:',
            expires => 'Thu, 25-Apr-1999 00:40:33 GMT',
            domain  => 'example.com',
            path => '/',
        },
        'poo_sid' => +{
            value => 'QWERTYUI',
            expires => 'Thu, 25-Apr-1999 00:40:33 GMT',
            domain  => 'example.com',
            path => '/',
        },
    },
    body => 'hello',
);

is($res->[0], 200);

is(scalar(@{ $res->[1] }), 4);
is($res->[1][0], 'Set-Cookie');
is($res->[1][2], 'Set-Cookie');
my @cookies = sort($res->[1][1], $res->[1][3]);
is($cookies[0], 'foo_sid=ASDFJKL%3A; domain=example.com; path=/; expires=Thu, 25-Apr-1999 00:40:33 GMT');
is($cookies[1], 'poo_sid=QWERTYUI; domain=example.com; path=/; expires=Thu, 25-Apr-1999 00:40:33 GMT');

is(scalar(@{ $res->[2] }), 1);
is($res->[2][0], 'hello');

done_testing;
