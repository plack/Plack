package Plack::Middleware::ContentMD5;

use strict;
use warnings;
use parent qw( Plack::Middleware );

use Plack::Util;
use Digest::MD5 qw/md5_hex/;

sub call {
    my $self = shift;
    my $res  = $self->app->(@_);
    
    $self->response_cb($res, sub {
        my $res = shift;

        return unless defined $res->[2];
        return if (Plack::Util::status_with_no_entity_body($res->[0]));
        
        my $h = Plack::Util::headers($res->[1]);
        return if ( $h->exists('Content-MD5') );
        
        my $body = $res->[2];
        if (ref $body eq 'ARRAY') {
            $h->set('Content-MD5', md5_hex(@$body));
        }
        # Do we need support $fh?

        return;
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::ContentMD5 - Automatically sets the Content-MD5 header on all String bodies

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable "Plack::Middleware::ContentMD5";
      $app;
  };

=head1 DESCRIPTION

Automatically sets the Content-MD5 header on all String bodies

=head1 AUTHOR

Fayland Lam

=cut
