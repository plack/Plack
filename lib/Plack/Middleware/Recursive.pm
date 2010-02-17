package Plack::Middleware::Recursive;
use strict;
use parent qw(Plack::Middleware);

use Try::Tiny;
use Scalar::Util qw(blessed);

open my $null_io, "<", \"";

sub call {
    my($self, $env) = @_;

    $env->{'plack.recursive.include'} = $self->recurse_callback($env);

    my $res = try {
        $self->app->($env);
    } catch {
        if (blessed $_ && $_->isa('Plack::Recursive::ForwardRequest')) {
            return $env->{'plack.recursive.include'}->($_->path);
        }
    };

    return $res;
}

sub recurse_callback {
    my($self, $env) = @_;

    my $old_path_info = $env->{PATH_INFO};

    return sub {
        my $new_path_info = shift;
        my($path, $query) = split /\?/, $new_path_info, 2;

        Scalar::Util::weaken($env);

        $env->{PATH_INFO}      = $path;
        $env->{QUERY_STRING}   = $query;
        $env->{REQUEST_METHOD} = 'GET';
        $env->{CONTENT_LENGTH} = 0;
        $env->{CONTENT_TYPE}   = '';
        $env->{'psgi.input'}   = $null_io;
        $env->{'plack.recursive.old_path_info'} = $old_path_info;

        $self->app->($env);
    };
}

package Plack::Recursive::ForwardRequest;
use overload q("") => \&as_string, fallback => 1;

sub new {
    my($class, $path) = @_;
    bless { path => $path }, $class;
}

sub path { $_[0]->{path} }

sub throw {
    my($class, @args) = @_;
    die $class->new(@args);
}

sub as_string {
    my $self = shift;
    return "Forwarding to $self->{path}: Your application should be wrapped with Plack::Middleware::Recursive.";
}

package Plack::Middleware::Recursive;

1;
