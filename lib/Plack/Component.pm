package Plack::Component;
use strict;
use warnings;
use Carp ();
use Plack::Util;
use overload '&{}' => sub { shift->to_app(@_) }, fallback => 1;

sub new {
    my $proto = shift;
    my $class = ref $proto || $proto;

    my $self;
    if (@_ == 1 && ref $_[0] eq 'HASH') {
        $self = bless {%{$_[0]}}, $class;
    } else {
        $self = bless {@_}, $class;
    }

    $self;
}

# NOTE:
# this is for back-compat only,
# future modules should use
# Plack::Util::Accessor directly
# or their own favorite accessor
# generator.
# - SL
sub mk_accessors {
    my $self = shift;
    Plack::Util::Accessor::mk_accessors( ref( $self ) || $self, @_ )
}

sub to_app {
    my $self = shift;
    return sub { $self->call(@_) };
}

1;

__END__

=head1 NAME

Plack::Component - Base class for easy-to-use PSGI middleware and endpoints

=head1 DESCRIPTION

Plack::Component is the base class shared between Plack::Middleware and
Plack::App::* modules. If you are writing middleware, you should inherit
from Plack::Middleware, but if you are writing a Plack::App::* you should
inherit from this directly.

=head1 SEE ALSO

L<Plack> L<Plack::Builder>

=cut
