use Test::More;
use Plack::Runner;

sub p {
    my $r = Plack::Runner->new;
    $r->parse_options(@_);
    return {@{$r->{options}}};
}

my %defaults = ( host => undef, port => 5000, listen => [ ':5000' ], socket => undef );

is_deeply p(), { %defaults };
is_deeply p('-l', '/tmp/foo.sock'),
    { host => undef, port => undef, listen => [ '/tmp/foo.sock' ], socket => '/tmp/foo.sock' };
is_deeply p('-o', '0.0.0.0', '--port', 9000),
    { host => '0.0.0.0', port => 9000, listen => [ '0.0.0.0:9000' ], socket => undef };
is_deeply p('-S', 'foo.sock'),
    { host => undef, port => undef, listen => [ 'foo.sock' ], socket => 'foo.sock' };
is_deeply p('-l', ':80'),
    { host => undef, port => 80, listen => [ ':80' ], socket => undef };
is_deeply p('-l', '10.0.0.1:80', '-l', 'unix.sock'),
    { host => '10.0.0.1', port => 80, listen => [ '10.0.0.1:80', 'unix.sock' ], socket => 'unix.sock' };
is_deeply p('-l', ':80', '--disable-foo', '--enable-bar'),
    { host => undef, port => 80, listen => [ ':80' ], socket => undef, foo => '', bar => 1 };
is_deeply p('-l', '10.0.0.1:80', '-l', '10.0.0.1:8080'),
    { host => '10.0.0.1', port => 80, listen => [ '10.0.0.1:80', '10.0.0.1:8080' ], socket => undef },
    'host/port set from first --listen option';
is_deeply p('-l', 'foo.sock', '-l', 'unix.sock'),
    { host => undef, port => undef, listen => [ 'foo.sock', 'unix.sock' ], socket => 'unix.sock' },
    'socket set from last --listen option';

{
    my $r = Plack::Runner->new;
    $r->parse_options('-D', '--workers=50', '-E', 'development', 'foo.psgi', '--list=4000');

    is $r->{env}, 'development';
    is $r->{daemonize}, 1;
    is_deeply $r->{argv}, [ 'foo.psgi' ];

    my $options = {@{$r->{options}}};
    is $options->{daemonize}, 1;
    is $options->{workers}, 50;
    is_deeply $options->{listen}, [ ':5000' ];
    is $options->{list}, '4000';
}

done_testing;

