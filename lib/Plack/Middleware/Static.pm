package Plack::Middleware::Static;
use strict;
use warnings;
use parent qw/Plack::Middleware/;
use Plack::App::File;

use Plack::Util::Accessor qw( path root encoding pass_through pass_env_not_path_info);

sub call {
    my $self = shift;
    my $env  = shift;

    my $res = $self->_handle_static($env);
    if ($res && not ($self->pass_through and $res->[0] == 404)) {
        return $res;
    }

    return $self->app->($env);
}

sub _handle_static {
    my($self, $env) = @_;

    my $path_match = $self->path or return;
    my $path = $env->{PATH_INFO};
    my $pass_env_not_path_info = $self->pass_env_not_path_info;

    for ($path) {
        my $matched = 'CODE' eq ref $path_match ? $path_match->($pass_env_not_path_info ? $env : $_) : $_ =~ $path_match;
        return unless $matched;
    }

    $self->{file} ||= Plack::App::File->new({ root => $self->root || '.', encoding => $self->encoding });
    local $env->{PATH_INFO} = $path; # rewrite PATH
    return $self->{file}->call($env);
}

1;
__END__

=encoding utf8

=head1 NAME

Plack::Middleware::Static - serve static files with Plack

=head1 SYNOPSIS

  use Plack::Builder;

  builder {
      enable "Plack::Middleware::Static",
          path => qr{^/(images|js|css)/}, root => './htdocs/';
      $app;
  };

=head1 DESCRIPTION

This middleware allows your Plack-based application to serve static files.

Note that if you are building an app using L<Plack::App::URLMap>, you should
consider using L<Plack::App::File> to serve static files instead. This makes
the overall routing of your application simpler to understand.

With this middleware, if a static file exists for the requested path, it will
be served. If it does not exist, by default this middleware returns a 404, but
you can set the C<pass_through> option to change this behavior.

If the requested document is not within the C<root> or the file is there but
not readable, this middleware will return a 403 Forbidden response.

The content type returned will be determined from the file extension by using
L<Plack::MIME>.

=head1 CONFIGURATIONS

=over 4

=item path, root

  enable "Plack::Middleware::Static",
      path => qr{^/static/}, root => 'htdocs/';

The C<path> option specifies the URL pattern (regular expression) or a
callback to match against requests. If the <path> option matches, the
middleware looks in C<root> to find the static files to serve. The default
value of C<root> is the current directory.

This example configuration serves C</static/foo.jpg> from
C<htdocs/static/foo.jpg>. Note that the matched portion of the path,
C</static/>, still appears in the locally mapped path under C<root>. If you
don't want this to happen, you can use a callback to munge the path as you
match it:

  enable "Plack::Middleware::Static",
      path => sub { s!^/static/!! }, root => 'static-files/';

The callback should operate on C<$_> and return a true or false value. Any
changes it makes to C<$_> are used when looking for the static file in the
C<root>.

The configuration above serves C</static/foo.png> from
C<static-files/foo.png>, not C<static-files/static/foo.png>. The callback
specified in the C<path> option matches against C<$_> munges this value using
C<s///>. The subsitution operator returns the number of matches it made, so it
will return true when the path matches C<^/static>.

If you want to map multiple static directories from different roots, simply
add this middleware multiple times with different configuration options.

=item pass_through

When this option is set to a true value, then this middleware will never
return a 404 if it cannot find a matching file. Instead, it will simply pass
the request on to the application it is wrapping.

=item pass_env_not_path_info

When this option is set to a true value callbacks specified via the
C<path> argument will get the C<$env> as an argument rather than
C<$env->{PATH_INFO}>.

C<$_> will always be set to C<$env->{PATH_INFO}> regardless of this
option.

=back

=head1 AUTHOR

Tokuhiro Matsuno, Tatsuhiko Miyagawa, Ævar Arnfjörð Bjarmason

=head1 SEE ALSO

L<Plack::Middleware> L<Plack::Builder>

=cut


