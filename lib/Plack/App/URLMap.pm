package Plack::App::URLMap;
use strict;
use warnings;
use base qw(Plack::Middleware);

use Carp ();

sub dispatch { shift->map(@_) }

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

sub to_app {
    my $self = shift;

    # sort by path length
    my $mapping = [
        map  { [ @{$_}[2..4] ] }
        sort { $b->[0] <=> $a->[0] || $b->[1] <=> $a->[1] }
        map  { [ ($_->[0] ? length $_->[0] : 0), length($_->[1]), @$_ ] } @{$self->{_mapping}},
    ];

    return sub {
        my $env = shift;

        my $path_info   = $env->{PATH_INFO};
        my $script_name = $env->{SCRIPT_NAME};

        my($http_host, $server_name, $server_port) = @{$env}{qw( HTTP_HOST SERVER_NAME SERVER_PORT )};

        for my $map (@$mapping) {
            my($host, $location, $app) = @$map;
            my $path = $path_info; # copy
            no warnings 'uninitialized';
            next unless $http_host   eq $host or
                        $server_name eq $host or
                        (!defined $host && ($http_host eq $server_name or $http_host eq "$server_name:$server_port"));
            next unless $path =~ s!\Q$location\E!!;
            next unless $path eq '' or $path =~ m!/!;

            return $app->({ %$env, PATH_INFO => $path, SCRIPT_NAME => $script_name . $location  });
        }

        return [404, [ 'Content-Type' => 'text/plain' ], [ "Not Found" ]];
    };
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

  my $app = Plack::App::URLMap->new;
  $app->map("/" => $app1);
  $app->map("/foo" => $app2);
  $app->map("http://bar.example.com/" => $app3);

  $app;

=head1 DESCRIPTION

TBD

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
