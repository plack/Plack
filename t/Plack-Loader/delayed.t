use strict;
use Test::More;
use Plack::Loader;

my $compiled;

my $builder = sub {
    $compiled = 1;
    my $app = sub {
        return [ 200, [], [ "Hi" ] ];
    };
};

# The following eval might not fail if you set PLACK_SEVER
delete $ENV{PLACK_SERVER};

eval {
    my $loader = Plack::Loader::Delayed->new;
    $loader->preload_app($builder);
    my $server = $loader->auto;
    ok(!$compiled);
};

ok 1 if $@;

done_testing;


