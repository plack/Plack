package Plack::App::URLMap;
use strict;
use warnings;
use parent qw(Plack::Component);
use constant DEBUG => $ENV{PLACK_URLMAP_DEBUG};

use Carp ();

sub mount { shift->map(@_) }

sub map {
    my $self = shift;
    my($location, $app) = @_;

    my $host;
    if ($location =~ m!^https?://(.*?)(/.*)!) {
        $host     = $1;
        $location = $2;
    }

    if ($location !~ m!^/!) {
        Carp::croak("Paths need to start with /");
    }
    $location =~ s!/$!!;

    push @{$self->{_mapping}}, [ $host, $location, $app ];
}

sub prepare_app {
    my $self = shift;
    # sort by path length
    $self->{_sorted_mapping} = [
        map  { [ @{$_}[2..4] ] }
        sort { $b->[0] <=> $a->[0] || $b->[1] <=> $a->[1] }
        map  { [ ($_->[0] ? length $_->[0] : 0), length($_->[1]), @$_ ] } @{$self->{_mapping}},
    ];
}

sub call {
    my ($self, $env) = @_;

    my $path_info   = $env->{PATH_INFO};
    my $script_name = $env->{SCRIPT_NAME};

    my($http_host, $server_name) = @{$env}{qw( HTTP_HOST SERVER_NAME )};

    if ($http_host and my $port = $env->{SERVER_PORT}) {
        $http_host =~ s/:$port$//;
    }

    for my $map (@{ $self->{_sorted_mapping} }) {
        my($host, $location, $app) = @$map;
        my $path = $path_info; # copy
        no warnings 'uninitialized';
        DEBUG && warn "Matching request (Host=$http_host Path=$path) and the map (Host=$host Path=$location)\n";
        next unless not defined $host     or
                    $http_host   eq $host or
                    $server_name eq $host;
        next unless $location eq '' or $path =~ s!^\Q$location\E!!;
        next unless $path eq '' or $path =~ m!^/!;
        DEBUG && warn "-> Matched!\n";

        my $orig_path_info   = $env->{PATH_INFO};
        my $orig_script_name = $env->{SCRIPT_NAME};

        $env->{PATH_INFO}  = $path;
        $env->{SCRIPT_NAME} = $script_name . $location;
        return $self->response_cb($app->($env), sub {
            $env->{PATH_INFO} = $orig_path_info;
            $env->{SCRIPT_NAME} = $orig_script_name;
        });
    }

    DEBUG && warn "All matching failed.\n";

    return [404, [ 'Content-Type' => 'text/plain' ], [ "Not Found" ]];
}

1;

__END__

=head1 NAME

Plack::App::URLMap - Map multiple apps in different paths

=head1 SYNOPSIS

  use Plack::App::URLMap;

  my $app1 = sub { ... };
  my $app2 = sub { ... };
  my $app3 = sub { ... };

  my $urlmap = Plack::App::URLMap->new;
  $urlmap->map("/" => $app1);
  $urlmap->map("/foo" => $app2);
  $urlmap->map("http://bar.example.com/" => $app3);

  my $app = $urlmap->to_app;

=head1 DESCRIPTION

Plack::App::URLMap is a PSGI application that can dispatch multiple
applications based on URL path and hostnames (a.k.a "virtual hosting")
and takes care of rewriting C<SCRIPT_NAME> and C<PATH_INFO>. This
module is inspired by Rack::URLMap.

=head1 METHODS

=over 4

=item map

  $urlmap->map("/foo" => $app);
  $urlmap->map("http://bar.example.com/" => $another_app);

Maps URL path or an absolute URL to a PSGI application. The match
order is sorted by host name length and then path length.

URL paths need to match from the beginning and should match completely
till the path separator (or the end of the path). For example, if you
register the path C</foo>, it B<will> match with the request C</foo>,
C</foo/> or C</foo/bar> but it B<won't> match with C</foox>.

Mapping URL with host names is also possible, and in that case the URL
mapping works like a virtual host.

=item mount

Alias for C<map>.

=item to_app

  my $handler = $urlmap->to_app;

Returns the PSGI application code reference. Note that the
Plack::App::URLMap object is callable (by overloading the code
dereference), so returning the object itself as a PSGI application
should also work.

=back

=head1 DEBUGGING

You can set the environment variable C<PLACK_URLMAP_DEBUG> to see how
this application matches with the incoming request host names and
paths.

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::Builder>

=cut
