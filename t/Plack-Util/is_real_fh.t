use Test::Base;
use Plack::Util;

plan tests => 2 * blocks;

run {
    my $block = shift;
    my $res = Plack::Util::is_real_fh(eval $block->input);

    ok !$@;
    ok $res == $block->ret;
};


__END__

===
--- input
open my $fh, "<", "/dev/null";
$fh;
--- ret
1

===
--- input
open my $fh, "<", \"foo"; $fh
--- ret
0

===
--- input
use IO::File;
IO::File->new("/dev/null");
--- ret
1


