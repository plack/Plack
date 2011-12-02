package Plack::App::Cascade;
use strict;
use base qw(Plack::Component);

use Plack::Util;
use Plack::Util::Accessor qw(apps catch codes);

sub add {
    my $self = shift;
    $self->apps([]) unless $self->apps;
    push @{$self->apps}, @_;
}

sub prepare_app {
    my $self = shift;
    my %codes = map { $_ => 1 } @{ $self->catch || [ 404 ] };
    $self->codes(\%codes);
}

sub call {
    my($self, $env) = @_;

    return sub {
        my $respond = shift;

        my $done;
        my $respond_wrapper = sub {
            my $res = shift;
            if ($self->codes->{$res->[0]}) {
                # suppress output by giving the app an
                # output spool which drops everything on the floor
                return Plack::Util::inline_object
                    write => sub { }, close => sub { };
            } else {
                $done = 1;
                return $respond->($res);
            }
        };

        my @try = @{$self->apps || []};
        my $tries_left = 0 + @try;

        if (not $tries_left) {
            return $respond->([ 404, [ 'Content-Type' => 'text/html' ], [ '404 Not Found' ] ])
        }

        for my $app (@try) {
            my $res = $app->($env);
            if ($tries_left-- == 1) {
                $respond_wrapper = sub { $respond->(shift) };
            }

            if (ref $res eq 'CODE') {
                $res->($respond_wrapper);
            } else {
                $respond_wrapper->($res);
            }
            return if $done;
        }
    };
}

1;

__END__

=head1 NAME

Plack::App::Cascade - Cascadable compound application

=head1 SYNOPSIS

  use Plack::App::Cascade;
  use Plack::App::URLMap;
  use Plack::App::File;

  # Serve static files from multiple search paths
  my $cascade = Plack::App::Cascade->new;
  $cascade->add( Plack::App::File->new(root => "/www/example.com/foo")->to_app );
  $cascade->add( Plack::App::File->new(root => "/www/example.com/bar")->to_app );

  my $app = Plack::App::URLMap->new;
  $app->map("/static", $cascade);
  $app->to_app;

=head1 DESCRIPTION

Plack::App::Cascade is a Plack middleware component that compounds
several apps and tries them to return the first response that is not
404.

=head1 METHODS

=over 4

=item new

  $app = Plack::App::Cascade->new(apps => [ $app1, $app2 ]);

Creates a new Cascade application.

=item add

  $app->add($app1);
  $app->add($app2, $app3);

Appends a new application to the list of apps to try. You can pass the
multiple apps to the one C<add> call.

=item catch

  $app->catch([ 403, 404 ]);

Sets which error codes to catch and process onwards. Defaults to C<404>.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::URLMap> Rack::Cascade

=cut
