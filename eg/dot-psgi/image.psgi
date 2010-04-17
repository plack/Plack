use File::Basename;
my $path = $ENV{PSGI_IMAGE_FILE} || dirname(__FILE__) . "/../../share/baybridge.jpg";
my $handler = sub {
    open my $fh, "<:raw", $path or die $!;
    return [ 200, [ "Content-Type" => "image/jpeg", "X-Sendfile" => $path, "Content-Length" => -s $fh ], $fh ];
};
