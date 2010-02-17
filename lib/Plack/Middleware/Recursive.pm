package Plack::Middleware::Recursive;
use strict;
use parent qw(Plack::Middleware);

open my $null_io, "<", \"";

sub call {
    my($self, $env) = @_;

    my $old_path_info = $env->{PATH_INFO};

    $env->{'plack.recursive.include'} = sub {
        my $new_path_info = shift;
        my($path, $query) = split /\?/, $new_path_info, 2;

        $env->{PATH_INFO}      = $path;
        $env->{QUERY_STRING}   = $query;
        $env->{REQUEST_METHOD} = 'GET';
        $env->{CONTENT_LENGTH} = 0;
        $env->{CONTENT_TYPE}   = '';
        $env->{'psgi.input'}   = $null_io;
        $env->{'plack.recursive.old_path_info'} = $old_path_info;

        $self->app->($env);
    };

    $self->app->($env);
}

1;
