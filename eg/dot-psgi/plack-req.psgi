use Plack::Request;
use Plack::Response;
sub {
    my $env = shift;
    my $req = Plack::Request->new($env);
    my $res = Plack::Response->new;
    $res->code(200);
    $res->header('Content-Type' => 'text/plain');
    $res->body("Hello " . $req->param('name'));
    $res->finalize;
}
