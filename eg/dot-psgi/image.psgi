use File::Basename;
my $path = $ENV{PSGI_IMAGE_FILE} || dirname(__FILE__) . "/../../t/assets/kyoto.jpg";
my $handler = sub {
    open my $fh, "<", $path or die $!;
    return [ 200, [ "Content-Type" => "image/jpeg", "Content-Length" => -s $fh ], $fh ];
};
