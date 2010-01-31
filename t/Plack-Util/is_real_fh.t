use strict;
use Test::More;
use Plack::Util;

{
    open my $fh, "<", "/dev/null";
    ok Plack::Util::is_real_fh($fh);
}

{
    open my $fh, "<", \"foo";
    ok ! Plack::Util::is_real_fh($fh);
}

{
    use IO::File;
    my $fh = IO::File->new("/dev/null");
    ok Plack::Util::is_real_fh($fh);
}

done_testing;

