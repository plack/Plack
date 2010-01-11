package Plack::App::Directory;
use parent qw(Plack::App::File);
use strict;
use warnings;
use Plack::Util;
use Path::Class;
use HTTP::Date;
use Plack::MIME;

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

sub should_handle {
    my($self, $file) = @_;
    return -d $file || -f $file;
}

sub serve_path {
    my($self, $env, $file, $fullpath) = @_;

    if (-f $file) {
        return $self->SUPER::serve_path($env, $file, $fullpath);
    }

    my $dir = dir($file);

    my @files = ([ "../", "Parent Directory", '', '', '' ]);

    my @children = map { [ ($_->is_dir ? ($_->dir_list)[-1] : $_->basename), $_ ] } $dir->children;

    for my $child (sort { $a->[0] cmp $b->[0] } @children) {
        my($basename, $file) = @$child;
        my $url = $env->{SCRIPT_NAME} . $env->{PATH_INFO} . $basename;

        if ($file->is_dir) {
            $basename .= "/";
            $url      .= "/";
        }

        my $mime_type = $file->is_dir ? 'directory' : ( Plack::MIME->mime_type($file) || 'text/plain' );
        my $stat = $file->stat;

        push @files, [ $url, $basename, $stat->size, $mime_type, HTTP::Date::time2str($stat->mtime) ];
    }

    my $path  = Plack::Util::encode_html("Index of $env->{PATH_INFO}");
    my $files = join "\n", map {
        my $f = $_;
        sprintf $dir_file, map Plack::Util::encode_html($_), @$f;
    } @files;
    my $page  = sprintf $dir_page, $path, $path, $files;

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

=head1 DESCRIPTION

This is a static file server PSGI application with directory index a la Apache's mod_autoindex.

=head1 CONFIGURATION

=over 4

=item root

Document root directory. Defaults to the current directory.

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::File>

=cut
