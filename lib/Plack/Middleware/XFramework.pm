package Plack::Middleware::XFramework;
use Moose;
use overload '&{}' => sub {
    my $self = $_[0];
    sub {
        my $res = $self->code->( @_ );
        push @{$res->[1]}, 'X-Framework' => $self->framework;
        $res;
    }
  },
  fallback => 1;

has framework => (
    is => 'ro',
    isa => 'Str',
);

has code => (
    is => 'ro',
    isa => 'CodeRef',
);

__PACKAGE__->meta->make_immutable;
