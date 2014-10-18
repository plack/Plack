package Plack::Middleware::ErrorDocument;
use strict;
use warnings;
use parent qw(Plack::Middleware);
use Plack::MIME;
use Plack::Util;
use Plack::Util::Accessor qw( subrequest );

use HTTP::Status qw(is_error);

sub call {
    my $self = shift;
    my $env  = shift;

    my $r = $self->app->($env);

    $self->response_cb($r, sub {
        my $r = shift;
        unless (is_error($r->[0]) && exists $self->{$r->[0]}) {
            return;
        }

        my $path = $self->{$r->[0]};
        if ($self->subrequest) {
            for my $key (keys %$env) {
                unless ($key =~ /^psgi/) {
                    $env->{'psgix.errordocument.' . $key} = $env->{$key};
                }
            }

            # TODO: What if SCRIPT_NAME is not empty?
            $env->{REQUEST_METHOD} = 'GET';
            $env->{REQUEST_URI}    = $path;
            $env->{PATH_INFO}      = $path;
            $env->{QUERY_STRING}   = '';
            delete $env->{CONTENT_LENGTH};

            my $sub_r = $self->app->($env);
            if ($sub_r->[0] == 200) {
                $r->[1] = $sub_r->[1];
                if (@$r == 3) {
                    $r->[2] = $sub_r->[2];
                }
                else {
                    my $full_sub_response = '';
                    Plack::Util::foreach($sub_r->[2], sub {
                        $full_sub_response .= $_[0];
                    });

                    my $returned;
                    return sub {
                        if ($returned) {
                            return defined($_[0]) ? '' : undef;
                        }
                        $returned = 1;
                        return $full_sub_response;
                    }
                }
            }
            # TODO: allow 302 here?
        } else {
            my $h = Plack::Util::headers($r->[1]);
            $h->remove('Content-Length');
            $h->remove('Content-Encoding');
            $h->remove('Transfer-Encoding');
            $h->set('Content-Type', Plack::MIME->mime_type($path));

            open my $fh, "<", $path or die "$path: $!";
            if ($r->[2]) {
                $r->[2] = $fh;
            } else {
                my $done;
                return sub {
                    unless ($done) {
                        $done = 1;
                        return join '', <$fh>;
                    }
                    return defined $_[0] ? '' : undef;
                };
            };
        }
    });
}

1;

__END__

=head1 NAME

Plack::Middleware::ErrorDocument - Set Error Document based on HTTP status code

=head1 SYNOPSIS

  # in app.psgi
  use Plack::Builder;

  builder {
      enable "Plack::Middleware::ErrorDocument",
          500 => '/uri/errors/500.html', 404 => '/uri/errors/404.html',
          subrequest => 1;
      $app;
  };

=head1 DESCRIPTION

Plack::Middleware::ErrorDocument allows you to customize error screen
by setting paths (file system path or URI path) of error pages per
status code.

=head1 CONFIGURATIONS

=over 4

=item subrequest

A boolean flag to serve error pages using a new GET sub request.
Defaults to false, which means it serves error pages using file
system path.

  builder {
      enable "Plack::Middleware::ErrorDocument",
          502 => '/home/www/htdocs/errors/maint.html';
      enable "Plack::Middleware::ErrorDocument",
          404 => '/static/404.html', 403 => '/static/403.html', subrequest => 1;
      $app;
  };

This configuration serves 502 error pages from file system directly
assuming that's when you probably maintain database etc. but serves
404 and 403 pages using a sub request so your application can do some
logic there like logging or doing suggestions.

When using a subrequest, the subrequest should return a regular '200' response.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

=cut
