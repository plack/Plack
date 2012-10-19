use strict;
use Plack::Loader::Restarter;
use Test::More;

my $r = Plack::Loader::Restarter->new;

my @match  = qw(Foo.pm foo.t lib/Bar.pm view/index.tt _myapp/foo.psgi .www/bar.pl _sass.css /Users/joe/foo/bar.pm);
my @ignore = qw(.git/123 .svn/abc Foo.pm~ _flymake.pl /Users/joe/foo.pl~ /foo/bar/x.txt.bak);

ok $r->valid_file({ path => $_ }), "$_ is valid" for @match;
ok !$r->valid_file({ path => $_ }), "$_ should be ignored" for @ignore;

done_testing;


