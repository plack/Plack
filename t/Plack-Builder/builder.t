use strict;
use Test::More tests => 1;
use Plack::Builder;

my $app = builder {
    mount "/" => sub { [ 200, ["Content-Type", "text/plain"], ["Hello"] ] };
};

is ref($app), 'CODE';
