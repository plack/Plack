use Test::More;
use Plack::Util;

open my $fh, "<", "t/00_compile.t";
Plack::Util::set_io_path($fh, "/path/to/00_compile.t");

is $fh->path, "/path/to/00_compile.t";

like scalar <$fh>, qr/use strict/;
like $fh->getline, qr/use Test::More/;
ok fileno $fh;

done_testing;
