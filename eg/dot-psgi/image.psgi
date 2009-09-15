use File::Basename;
my $path = dirname(__FILE__) . "/../../t/assets/face.jpg";
my $handler = sub {
    open my $fh, "<", $path or die $!;
    return [ 200, [ "Content-Type" => "image/jpeg", "Content-Length" => -s $fh ], $fh ];
};
