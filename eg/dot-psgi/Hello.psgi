my $handler = sub {
    die "Foo";
    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => 11 ], [ "Hello World" ] ];
};
