package Plack::Middleware::IIS7KeepAliveFix;

use strict;
use parent 'Plack::Middleware';
use Plack::Util;

sub call {
    my($self, $env) = @_;
        # Fixes buffer being cut off on redirect when keep-alive is active
        my $res  = $self->app->($env);

        Plack::Util::response_cb($res, sub {
            my $res = shift;
            if ($res->[0] =~ m!^30[123]$! ) {
                Plack::Util::header_remove($res->[1], 'Content-Length');
                Plack::Util::header_remove($res->[1], 'Content-Type');
               return sub{ my $chunk; return unless defined $chunk; return ''; };
            }

            return;
        });

}

1;
__END__

=head1 NAME

Plack::Middleware::IIS7KeepAliveFix - fixes buffer being cut off on redirect when keep-alive is active on IIS.

=head1 SYNOPSIS

  # in your app.psgi
  use Plack::Builder;

  builder {
    enable "IIS7KeepAliveFix";
    $app;
  };

  # Or from the command line
  plackup -s FCGI -e 'enable "IIS7KeepAliveFix"' /path/to/app.psgi

=head1 DESCRIPTION

This middleware fixes buffer being cut off on redirect when keep-alive is active on IIS7.

=head1 AUTHORS

KnowZeroX

=cut

