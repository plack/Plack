use strict;
use Plack::Loader::Restarter;
use Test::More;

my $r = Plack::Loader::Restarter->new;

my @match  = qw(
    Foo.pm foo.t lib/Bar.pm view/index.tt _myapp/foo.psgi .www/bar.pl _sass.css /Users/joe/foo/bar.pm
    /path/to/4912 /path/to/5037
);
my @ignore = qw(
    .git/123 .svn/abc Foo.pm~ _flymake.pl /Users/joe/foo.pl~ /foo/bar/x.txt.bak
    /path/to/foo.swp /path/to/foo.swpx /path/to/foo.swx
    /path/to/4913 /path/to/5036
    /path/to/.#Foo.pm
);

ok $r->valid_file({ path => $_ }), "$_ is valid" for @match;
ok !$r->valid_file({ path => $_ }), "$_ should be ignored" for @ignore;

done_testing;


