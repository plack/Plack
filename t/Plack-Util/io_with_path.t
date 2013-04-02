use Test::More;
use Plack::Util;

open my $fh, "<", "t/test.txt";
Plack::Util::set_io_path($fh, "/path/to/test.txt");

is $fh->path, "/path/to/test.txt";

like scalar <$fh>, qr/foo/;
ok fileno $fh;

isa_ok $fh, 'IO::Handle';

done_testing;
