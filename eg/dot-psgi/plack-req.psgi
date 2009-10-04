use Plack::Request;
use Plack::Response;
sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $res = $req->new_response(200);
    $res->content_type('text/plain');
    $res->body("Hello " . $req->param('name'));
    $res->finalize;
}
