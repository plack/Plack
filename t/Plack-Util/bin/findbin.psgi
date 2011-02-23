use FindBin;
sub { [ 200, [ "Content-Type", "text/plain" ], [ "$FindBin::Bin" ] ] };
