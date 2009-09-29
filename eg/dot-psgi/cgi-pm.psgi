use CGI::PSGI;
sub {
    my $env = shift;
    my $query = CGI::PSGI->new($env);
#    return [ 200, [ "Content-Type" => "text/plain" ], [ "Hello ", $query->param('name') ] ];
    return [ $query->psgi_header('text/plain'), [ "Hello ", $query->param('name') ] ];
}