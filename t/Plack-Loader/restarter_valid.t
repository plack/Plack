use strict;
use Plack::Loader::Restarter;
use Test::More;

my $r = Plack::Loader::Restarter->new;

my @match  = qw(Foo.pm foo.t lib/Bar.pm view/index.tt _myapp/foo.psgi /Users/joe/foo/bar.pm);
my @ignore = qw(.xxx Foo.pm~ _flymake.pl foo/.bar.pm /Users/joe/foo.pl~);

ok $r->valid_file({ path => $_ }), "$_ is valid" for @match;
ok !$r->valid_file({ path => $_ }), "$_ should be ignored" for @ignore;

done_testing;


