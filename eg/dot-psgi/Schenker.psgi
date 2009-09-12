require "myapp.pl";

my $engine = HTTP::Engine->new(
    interface => {
        module => 'PSGI',
        request_handler => sub { Schenker::request_handler(@_) },
    }
);

Schenker::init;
sub { Schenker::Engine->run(@_) };
