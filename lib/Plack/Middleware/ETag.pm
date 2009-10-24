package Plack::Middleware::ETag;

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
        return if ( $h->exists('ETag') );
        
        my $body = $res->[2];
        if (ref $body eq 'ARRAY') {
            $h->set('ETag', md5_hex(@$body));
        }
        # Do we need support $fh?

        return;
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::ETag - Automatically sets the ETag header on all String bodies

=head1 SYNOPSIS

  use Plack::Builder;

  my $app = sub {
      return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello Foo' ] ];
  };

  builder {
      enable "Plack::Middleware::ETag";
      $app;
  };

=head1 DESCRIPTION

Automatically sets the ETag header on all String bodies

=head1 SEE ALSO

L<http://github.com/rack/rack-contrib/blob/master/lib/rack/contrib/etag.rb>

=head1 AUTHOR

Fayland Lam

=cut
