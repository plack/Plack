use strict;
use warnings;
use Test::More 0.98;
use File::Temp qw(tempdir);

plan skip_all => "AUTHOR_TESTING is required." unless $ENV{AUTHOR_TESTING};

my @downstream = qw(
  Starman Starlet Twiggy Monoceros
  OX Dancer2 Catalyst
);

for my $module (@downstream) {
    my $tmp = tempdir(CLEANUP => 1);
    is(system("cpanm --notest -l $tmp ."), 0);
    is(system("cpanm -l $tmp --test-only $module"), 0, $module);
}

done_testing;
