use strict;
no warnings 'redefine';
use Test::More;
use Plack::Loader;

my $builder = sub {
    my $app = sub {
        return [ 200, [], [ "Hi" ] ];
    };
};

local *Plack::Loader::guess = sub { 'NonExistent' };
local $SIG{__WARN__} = sub { like $_[0], qr/Autoloading/ };

my $loader = Plack::Loader->new;
$loader->preload_app($builder);
my $server = $loader->auto;

like ref $server, qr/Standalone/;

done_testing;


