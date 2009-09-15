use Data::Dumper;
my $handler = sub {
    my $env = shift;
    return [ 200, [ "Content-Type" => "text/plain" ], [ Dumper $env ] ];
};
