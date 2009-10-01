use MyMojoApp;
use Mojo::Server::PSGI;

$ENV{MOJO_APP} = 'MyMojoApp';
my $handler = sub { Mojo::Server::PSGI->new->run(@_) };
