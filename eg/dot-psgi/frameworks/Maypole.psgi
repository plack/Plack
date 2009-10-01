use BeerDB;
use Maypole::PSGI;

my $app = Maypole::PSGI->new('BeerDB');
my $handler = sub { $app->run(@_) };
