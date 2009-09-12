use Foo;
Foo->setup_engine('PSGI');
sub { Foo->new->run(@_) };

