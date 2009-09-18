package Plack::Builder;
use strict;
use base qw( Exporter );

our @EXPORT = qw( builder );

sub builder(&) {
    my $block = shift;

    my @builders;
    local *Plack::Middleware::enable = sub {
        my($class, @args) = @_;
        push @builders, sub { $class->wrap(@args, $_[0]) };
    };

    my $app = $block->();

    for my $mw (reverse @builders) {
        $app = $mw->($app);
    }

    return $app;
}

1;

__END__

=head1 NAME

Plack::Builder - DSL to enable Plack::Middleware in .psgi files

=head1 SYNOPSIS

  use Plack::Builder
  use Plack::Middleware qw( Foo Bar Baz );

  my $app = sub { ... };

  builder {
     enable Plack::Middleware::Foo;
     enable Plack::Middleware::Bar opt => "val";
     enable Plack::Middleware::Baz;
     $app;
  };

=head1 DESCRIPTION

Plack::Builder gives you a quick DSL to wrap your application with
Plack::Middleware subclasses. The middleware you're trying to use
should use L<Plack::Middleware> as a base class to use this DSL,
inspired by Rack::Builder.

=head1 SEE ALSO

L<Plack::Middleware>

=cut



