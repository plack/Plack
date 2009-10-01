use HTML::Mason::PSGIHandler;
use HTTP::Response;

my $h = HTML::Mason::PSGIHandler->new(
    comp_root => $ENV{DOCUMENT_ROOT} || "$ENV{HOME}/Sites",
);

my $handler = sub { $h->handle_psgi(@_) };
