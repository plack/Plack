my $handler = sub {
    my $string = "Hello, World!";
    return [ 200, [ "Content-Type" => "text/plain", "Content-Length" => length $string ], [ $string ] ];
};
