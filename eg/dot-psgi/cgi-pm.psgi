use CGI::PSGI;
sub {
    my $env = shift;
    local *ENV = $env;
    my $query = CGI->new;

    return [ 200, [ "Content-Type" => "text/plain" ], [ "Hello ", $query->param('name') ] ];
}