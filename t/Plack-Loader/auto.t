use strict;
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

# The following eval might not fail if you set PLACK_SEVER
delete $ENV{PLACK_SERVER};

eval {
    my $loader = Plack::Loader->new;
    $loader->preload_app($builder);
    my $server = $loader->auto;

    like ref $server, qr/Twiggy/;
};

ok 1 if $@;

done_testing;


