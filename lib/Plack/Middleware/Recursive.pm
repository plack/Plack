package Plack::Middleware::Recursive;
use strict;
use parent qw(Plack::Middleware);

use Try::Tiny;
use Scalar::Util qw(blessed);

open my $null_io, "<", \"";

sub call {
    my($self, $env) = @_;

    $env->{'plack.recursive.include'} = $self->recurse_callback($env, 1);

    my $res = try {
        $self->app->($env);
    } catch {
        if (blessed $_ && $_->isa('Plack::Recursive::ForwardRequest')) {
            return $self->recurse_callback($env)->($_->path);
        } else {
            die $_; # rethrow
        }
    };

    return $res if ref $res eq 'ARRAY';

    return sub {
        my $respond = shift;

        my $writer;
        try {
            $res->(sub { return $writer = $respond->(@_) });
        } catch {
            if (!$writer && blessed $_ && $_->isa('Plack::Recursive::ForwardRequest')) {
                $res = $self->recurse_callback($env)->($_->path);
                return ref $res eq 'CODE' ? $res->($respond) : $respond->($res);
            } else {
                die $_;
            }
        };
    };
}

sub recurse_callback {
    my($self, $env, $include) = @_;

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
        push @{$env->{'plack.recursive.old_path_info'}}, $old_path_info;

        $include ? $self->app->($env) : $self->call($env);
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

__END__

=head1 NAME

Plack::Middleware::Recursive - Allows PSGI apps to include or forward requests recursively

=head1 SYNOPSIS

  # with Builder
  enable "Recursive";

  # in apps
  my $res = $env->{'plack.recursive.include'}->("/new_path");

  # Or, use exceptions
  my $app = sub {
      # ...
      Plack::Recursive::ForwardRequest->throw("/new_path");
  };

=head1 DESCRIPTION

Plack::Middleware::Recursive allows PSGI applications to recursively
include or forward requests to other paths. Applications can make use
of callbacks stored in C<< $env->{'plack.recursive.include'} >> to
I<include> another path to get the response (whether it's an array ref
or a code ref depending on your application), or throw an exception
Plack::Recursive::ForwardRequest anywhere in the code to I<forward>
the current request (i.e. abort the current and redo the request).

=head1 EXCEPTIONS

This middleware passes through unknown exceptions to the outside
middleware stack, so if you use this middleware with other exception
handlers such as L<Plack::Middleware::StackTrace> or
L<Plack::Middleware::HTTPExceptions>, be sure to wrap this so
L<Plack::Middleware::Recursive> gets as inner as possible.

=head1 AUTHORS

Tatsuhiko Miyagawa

Masahiro Honma

=head1 SEE ALSO

L<Plack> L<Plack::Middleware::HTTPExceptions>

The idea, code and interface are stolen from Rack::Recursive and paste.recursive.

=cut


