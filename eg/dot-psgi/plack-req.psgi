use Plack::Request;
sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    return [ 200, [ "Content-Type" => "text/plain" ], [ "Hello ", $req->param('name') ] ];
}
