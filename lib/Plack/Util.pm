package Plack::Util;
use strict;

# Is it safe to use Scalar::Util everywhere?
sub _blessed {
    ref $_[0] && ref($_[0]) !~ /^(?:SCALAR|ARRAY|HASH|CODE|GLOB|Regexp)$/;
}

sub load_class {
    my $class = shift;

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm";

    return $class;
}

sub foreach {
    my($body, $cb) = @_;

    if (ref $body eq 'ARRAY') {
        for my $line (@$body) {
            $cb->($line);
        }
    } else {
        while (defined(my $line = $body->getline)) {
            $cb->($line);
        }
        $body->close;
    }
}

sub response_handle {
    my %methods = @_;
    Plack::Util::ResponseHandle->new(%methods);
}

package Plack::Util::ResponseHandle;

sub new {
    my($class, %methods) = @_;

    my $self = bless [ ], $class;
    $self->[0] = $methods{write} or do { require Carp; Carp::croak("write() should be implemented.") };
    $self->[1] = $methods{close} || sub {};

    return $self;
}

sub write { $_[0]->[0]->(@_[1..$#_]) }
sub close { $_[0]->[1]->(@_[1..$#_]) }

1;
