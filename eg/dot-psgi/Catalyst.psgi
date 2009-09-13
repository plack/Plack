use Foo;
Foo->setup_engine('PSGI');
my $handler = sub { Foo->new->run(@_) };

