use BeerDB;
use Maypole::PSGI;

my $handler = sub { Maypole::PSGI->run('BeerDB', @_) };
