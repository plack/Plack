use strict;
use warnings;
use Test::More;
use Plack::Util;

{
    package Foo;
    sub new { bless {}, shift }
}

do {
    for my $body ('error', \'error', qr//, +{}, sub {}, Foo->new()) {
        eval {
            Plack::Util::foreach($body, sub {});
        };
        like $@, qr/Can't (call|locate object) method "getline"/;
    }
};

do {
    my @x = (0, 1);
    Plack::Util::foreach([0, 1], sub { my $line = shift; is($line, $x[$line]) });
};

{
    package Bar;
    sub new { bless { i => 0 }, shift }
    my @x = (2, 3);
    sub getline {
        my $self = shift;
        $x[$self->{i}++];
    }
    sub current { $x[shift->{i}-1] }
    sub close { ::ok(1, 'close') }
}

do {
    my $bar = Bar->new;
    Plack::Util::foreach($bar, sub { my $line = shift; is($line, $bar->current) });
};

done_testing;
