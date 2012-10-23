use strict;
use Plack::Util;
use Plack::Test;
use HTTP::Request::Common;
use Test::More;

{
    my $app = Plack::Util::load_psgi("t/Plack-Util/hello.psgi");
    ok $app;

    test_psgi $app, sub {
        is $_[0]->(GET "/")->content, "Hello";
    };
}

{
    my $app = Plack::Util::load_psgi("t/Plack-Util/bad.psgi");
    ok $app;
    ok !$INC{"CGI.pm"};
}

{
    my $app = Plack::Util::load_psgi("t/Plack-Util/bad2.psgi");
    ok $app;
    eval { Plack::Util::load_class("Plack") };
    is $@, '';
}

{
    use lib "t/Plack-Util";
    my $app = Plack::Util::load_psgi("Hello");
    ok $app;
    test_psgi $app, sub {
        is $_[0]->(GET "/")->content, "Hello";
    };
}

{
    eval { Plack::Util::load_psgi("t/Plack-Util/error.psgi") };
    like $@, qr/Global symbol/;
}

{
    eval { Plack::Util::load_psgi("t/Plack-Util/nonexistent.psgi") };
    unlike $@, qr/Died/;
}

{
    my $app = Plack::Util::load_psgi("t/Plack-Util/bin/findbin.psgi");
    test_psgi $app, sub {
        like $_[0]->(GET "/")->content, qr!t[/\\]Plack-Util[/\\]bin$!;
    }
}

{
    require Cwd;
    my $cwd = Cwd::cwd();

    chdir "t/Plack-Util";
    local @INC = ("./inc", @INC);
    my $app = Plack::Util::load_psgi("hello.psgi");
    ok $app;
    test_psgi $app, sub {
        is $_[0]->(GET "/")->content, "Hello";
    };

    chdir $cwd;
}

{
    is Plack::Util::_relativize("/foo/bar.psgi"), "/foo/bar.psgi";
    is Plack::Util::_relativize("foo.psgi"), "./foo.psgi";
    is Plack::Util::_relativize('C:\x\y.psgi'), 'C:\x\y.psgi';
}

done_testing;
