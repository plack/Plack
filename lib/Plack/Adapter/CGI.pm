package Plack::Adapter::CGI;
use strict;
use warnings;
use IO::File;
use HTTP::Status;
use HTTP::Response;
use Carp ();
use CGI::PSGIfy;

sub new {
    my($class, $code) = @_;
    bless { code => $code }, $class;
}

sub handler {
    my $self = shift;
    CGI::PSGIfy->handler($self->{code});
}

1;
__END__

=head1 SYNOPSIS

    use Plack::Adapter::CGI;
    my $app = Plack::Adapter::CGI->new(sub { do "/path/to/bar.cgi" })->handler;

=cut


