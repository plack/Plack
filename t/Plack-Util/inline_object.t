use Test::More;
use Plack::Util;
use Try::Tiny;

my $counter;
my $object = Plack::Util::inline_object(
    method1 => sub { $counter++ },
);

$object->method1;
is $counter, 1, 'method call works';

my $sub = $object->can('method1');
ok $sub, 'can returns true value for method';
try { $sub->($object) };
is $counter, 2, 'can returns sub ref for method';

ok ! try { $object->method2; 1 }, 'croaks if nonexistant method called';
is $object->can('method2'), undef, 'can returns undef for nonexistant method';

done_testing;
