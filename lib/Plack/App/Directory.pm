package Plack::App::Directory;
use parent qw(Plack::App::File);
use strict;
use warnings;
use Plack::Util;
use Plack::Util::Accessor 'render_cb';
use HTTP::Date;
use Plack::MIME;
use DirHandle;
use URI::Escape;
use Plack::Request;

# Stolen from rack/directory.rb
my $dir_file = "<tr><td class='name'><a href='%s'>%s</a></td><td class='size'>%s</td><td class='type'>%s</td><td class='mtime'>%s</td></tr>";
my $dir_page = <<PAGE;
<html><head>
  <title>%s</title>
  <meta http-equiv="content-type" content="text/html; charset=utf-8" />
  <style type='text/css'>
table { width:100%%; }
.name { text-align:left; }
.size, .mtime { text-align:right; }
.type { width:11em; }
.mtime { width:15em; }
  </style>
</head><body>
<h1>%s</h1>
<hr />
<table>
  <tr>
    <th class='name'>Name</th>
    <th class='size'>Size</th>
    <th class='type'>Type</th>
    <th class='mtime'>Last Modified</th>
  </tr>
%s
</table>
<hr />
</body></html>
PAGE

sub render_index {
  my $self = shift;
  my ($path, @files) = @_;

  my $title = Plack::Util::encode_html("Index of $path");
  my $files = join "\n", map {
      my $f = $_;
      sprintf $dir_file, map Plack::Util::encode_html($_), @$f;
  } @files;

  return sprintf $dir_page, $title, $title, $files;
}

sub should_handle {
    my($self, $file) = @_;
    return -d $file || -f $file;
}

sub return_dir_redirect {
    my ($self, $env) = @_;
    my $uri = Plack::Request->new($env)->uri;
    return [ 301,
        [
            'Location' => $uri . '/',
            'Content-Type' => 'text/plain',
            'Content-Length' => 8,
        ],
        [ 'Redirect' ],
    ];
}

sub serve_path {
    my($self, $env, $dir) = @_;

    if (-f $dir) {
        return $self->SUPER::serve_path($env, $dir);
    }

    my $dir_url = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    if ($dir_url !~ m{/$}) {
        return $self->return_dir_redirect($env);
    }

    my @files = ([ "../", "Parent Directory", '', '', '' ]);

    my $dh = DirHandle->new($dir);
    my @children;
    while (defined(my $ent = $dh->read)) {
        next if $ent eq '.' or $ent eq '..';
        push @children, $ent;
    }

    for my $basename (sort { $a cmp $b } @children) {
        my $file = "$dir/$basename";
        my $url = $dir_url . $basename;

        my $is_dir = -d $file;
        my @stat = stat _;

        $url = join '/', map {uri_escape($_)} split m{/}, $url;

        if ($is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        my $mime_type = $is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        push @files, [ $url, $basename, $stat[7], $mime_type, HTTP::Date::time2str($stat[9]) ];
    }

    my $page = $self->render_cb ?
               $self->render_cb->($env->{PATH_INFO}, @files) :
               $self->render_index($env->{PATH_INFO}, @files);

    return [ 200, ['Content-Type' => 'text/html; charset=utf-8'], [ $page ] ];
}

1;

__END__

=head1 NAME

Plack::App::Directory - Serve static files from document root with directory index

=head1 SYNOPSIS

  # app.psgi
  use Plack::App::Directory;
  my $app = Plack::App::Directory->new({ root => "/path/to/htdocs" })->to_app;

Or

  my $app = Plack::App::Directory->new({
    root      => "/path/to/htdocs",
    render_cb => \&render,
  })->to_app;

  sub render {
    my ($path, @files) = @_;

    # Code to render an HTML page

    return $html;
  }

=head1 DESCRIPTION

This is a static file server PSGI application with directory index a la Apache's mod_autoindex.

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to the current directory.

=item render_cb

A reference to a subroutine that takes information about a directory and
returns the HTML to display that directory - this is used to override the
default display of the directory.

The first argument passed to this subroutine is the name of the path that
is being displayed. All other arguments contain information about the
files in the directory. Each of these arguments is a reference to an
array with five elements. These elements are:

=over 4

=item *

The URL of the file

=item *

The name of the file

=item *

The size of the file in bytes

=item *

The MIME type of the file

=item *

The last modified date of the file

=back

This subroutine is expected to return a string of HTML which will be
returned to the browser.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::File>

=cut
