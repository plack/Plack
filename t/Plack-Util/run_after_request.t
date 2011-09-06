use Test::More;
use Plack::Util;
use strict;

my $x = 0;
{
    my $guard = Plack::Util::guard { $x++ };
    is($x, 0, 'guard has not fired yet');
}
is($x, 1, 'guard has fired');

my %x;
{
    my $env = {};
    {
        Plack::Util::run_after_request($env, sub { $x{a} = 1 });
        Plack::Util::run_after_request($env, sub { $x{b} = 2 });
    }
    is_deeply(\%x, {}, 'guards have not fired yet');
}
is_deeply(\%x, { a => 1, b => 2 }, 'multiple guards fired');

done_testing;
