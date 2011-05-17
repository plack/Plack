use strict;
use warnings;
use Test::More;
use Plack::Loader;

my $builder = sub {
    require AnyEvent;
    my $app = sub {
        return [ 200, [], [ "Hi" ] ];
    };
};

$INC{"Plack/Handler/Twiggy.pm"} = __FILE__;
sub Plack::Handler::Twiggy::new { bless {}, shift }

no warnings 'redefine';
local *Plack::Loader::env = sub { return {} };

eval {
    my $loader = Plack::Loader->new;
    $loader->preload_app($builder);
    my $server = $loader->auto;

    like ref $server, qr/Twiggy/;
};

ok 1 if $@;

done_testing;


