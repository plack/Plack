use strict;
use warnings;
use Test::More;
use Plack::Util;

my $can;
my $lives = eval { $can = Plack::Util->can('something_obviously_fake'); 1 };
ok($lives, "Did not die calling 'can' on Plack::Util package with invalid sub");
is($can, undef, "Cannot do that method");

$lives = eval { $can = Plack::Util->can('content_length'); 1 };
ok($lives, "Did not die calling 'can' on Plack::Util package with real sub");
is($can, \&Plack::Util::content_length, "can() returns the sub");

done_testing;
