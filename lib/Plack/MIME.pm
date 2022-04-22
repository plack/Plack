package Plack::MIME;
use strict;

# stolen from rack.mime.rb
our $MIME_TYPES = {
    ".3gp"     => "video/3gpp",
    ".a"       => "application/octet-stream",
    ".ai"      => "application/postscript",
    ".aif"     => "audio/x-aiff",
    ".aiff"    => "audio/x-aiff",
    ".apk"     => "application/vnd.android.package-archive",
    ".asc"     => "application/pgp-signature",
    ".asf"     => "video/x-ms-asf",
    ".asm"     => "text/x-asm",
    ".asx"     => "video/x-ms-asf",
    ".atom"    => "application/atom+xml",
    ".au"      => "audio/basic",
    ".avi"     => "video/x-msvideo",
    ".bat"     => "application/x-msdownload",
    ".bin"     => "application/octet-stream",
    ".bmp"     => "image/bmp",
    ".bz2"     => "application/x-bzip2",
    ".c"       => "text/x-c",
    ".cab"     => "application/vnd.ms-cab-compressed",
    ".cc"      => "text/x-c",
    ".chm"     => "application/vnd.ms-htmlhelp",
    ".class"   => "application/octet-stream",
    ".collection" => "font/collection",
    ".com"     => "application/x-msdownload",
    ".conf"    => "text/plain",
    ".cpp"     => "text/x-c",
    ".crt"     => "application/x-x509-ca-cert",
    ".css"     => "text/css",
    ".csv"     => "text/csv",
    ".cxx"     => "text/x-c",
    ".deb"     => "application/x-debian-package",
    ".der"     => "application/x-x509-ca-cert",
    ".diff"    => "text/x-diff",
    ".djv"     => "image/vnd.djvu",
    ".djvu"    => "image/vnd.djvu",
    ".dll"     => "application/x-msdownload",
    ".dmg"     => "application/octet-stream",
    ".doc"     => "application/msword",
    ".dot"     => "application/msword",
    ".dtd"     => "application/xml-dtd",
    ".dvi"     => "application/x-dvi",
    ".ear"     => "application/java-archive",
    ".eml"     => "message/rfc822",
    ".eot"     => "application/vnd.ms-fontobject",
    ".eps"     => "application/postscript",
    ".exe"     => "application/x-msdownload",
    ".f"       => "text/x-fortran",
    ".f77"     => "text/x-fortran",
    ".f90"     => "text/x-fortran",
    ".flv"     => "video/x-flv",
    ".for"     => "text/x-fortran",
    ".gem"     => "application/octet-stream",
    ".gemspec" => "text/x-script.ruby",
    ".gif"     => "image/gif",
    ".gz"      => "application/x-gzip",
    ".h"       => "text/x-c",
    ".hh"      => "text/x-c",
    ".htm"     => "text/html",
    ".html"    => "text/html",
    ".ico"     => "image/vnd.microsoft.icon",
    ".ics"     => "text/calendar",
    ".ifb"     => "text/calendar",
    ".iso"     => "application/octet-stream",
    ".jar"     => "application/java-archive",
    ".java"    => "text/x-java-source",
    ".jnlp"    => "application/x-java-jnlp-file",
    ".jpeg"    => "image/jpeg",
    ".jpg"     => "image/jpeg",
    ".js"      => "text/javascript",
    ".json"    => "application/json",
    ".log"     => "text/plain",
    ".m3u"     => "audio/x-mpegurl",
    ".m4v"     => "video/mp4",
    ".man"     => "text/troff",
    ".manifest"=> "text/cache-manifest",
    ".mathml"  => "application/mathml+xml",
    ".mbox"    => "application/mbox",
    ".mdoc"    => "text/troff",
    ".me"      => "text/troff",
    ".mid"     => "audio/midi",
    ".midi"    => "audio/midi",
    ".mime"    => "message/rfc822",
    ".mml"     => "application/mathml+xml",
    ".mng"     => "video/x-mng",
    ".mov"     => "video/quicktime",
    ".mp3"     => "audio/mpeg",
    ".mp4"     => "video/mp4",
    ".mp4v"    => "video/mp4",
    ".mpeg"    => "video/mpeg",
    ".mpg"     => "video/mpeg",
    ".ms"      => "text/troff",
    ".msi"     => "application/x-msdownload",
    ".odp"     => "application/vnd.oasis.opendocument.presentation",
    ".ods"     => "application/vnd.oasis.opendocument.spreadsheet",
    ".odt"     => "application/vnd.oasis.opendocument.text",
    ".ogg"     => "application/ogg",
    ".ogv"     => "video/ogg",
    ".otf"     => "font/otf",
    ".p"       => "text/x-pascal",
    ".pas"     => "text/x-pascal",
    ".pbm"     => "image/x-portable-bitmap",
    ".pdf"     => "application/pdf",
    ".pem"     => "application/x-x509-ca-cert",
    ".pgm"     => "image/x-portable-graymap",
    ".pgp"     => "application/pgp-encrypted",
    ".pkg"     => "application/octet-stream",
    ".pl"      => "text/x-script.perl",
    ".pm"      => "text/x-script.perl-module",
    ".png"     => "image/png",
    ".pnm"     => "image/x-portable-anymap",
    ".ppm"     => "image/x-portable-pixmap",
    ".pps"     => "application/vnd.ms-powerpoint",
    ".ppt"     => "application/vnd.ms-powerpoint",
    ".ps"      => "application/postscript",
    ".psd"     => "image/vnd.adobe.photoshop",
    ".py"      => "text/x-script.python",
    ".qt"      => "video/quicktime",
    ".ra"      => "audio/x-pn-realaudio",
    ".rake"    => "text/x-script.ruby",
    ".ram"     => "audio/x-pn-realaudio",
    ".rar"     => "application/x-rar-compressed",
    ".rb"      => "text/x-script.ruby",
    ".rdf"     => "application/rdf+xml",
    ".roff"    => "text/troff",
    ".rpm"     => "application/x-redhat-package-manager",
    ".rss"     => "application/rss+xml",
    ".rtf"     => "application/rtf",
    ".ru"      => "text/x-script.ruby",
    ".s"       => "text/x-asm",
    ".sfnt"    => "font/sfnt",
    ".sgm"     => "text/sgml",
    ".sgml"    => "text/sgml",
    ".sh"      => "application/x-sh",
    ".sig"     => "application/pgp-signature",
    ".snd"     => "audio/basic",
    ".so"      => "application/octet-stream",
    ".svg"     => "image/svg+xml",
    ".svgz"    => "image/svg+xml",
    ".swf"     => "application/x-shockwave-flash",
    ".t"       => "text/troff",
    ".tar"     => "application/x-tar",
    ".tbz"     => "application/x-bzip-compressed-tar",
    ".tcl"     => "application/x-tcl",
    ".tex"     => "application/x-tex",
    ".texi"    => "application/x-texinfo",
    ".texinfo" => "application/x-texinfo",
    ".text"    => "text/plain",
    ".tif"     => "image/tiff",
    ".tiff"    => "image/tiff",
    ".torrent" => "application/x-bittorrent",
    ".tr"      => "text/troff",
    ".ttf"     => "font/ttf",
    ".txt"     => "text/plain",
    ".vcf"     => "text/x-vcard",
    ".vcs"     => "text/x-vcalendar",
    ".vrml"    => "model/vrml",
    ".war"     => "application/java-archive",
    ".wav"     => "audio/x-wav",
    ".webm"    => "video/webm",
    ".webp"    => "image/webp",
    ".wma"     => "audio/x-ms-wma",
    ".wmv"     => "video/x-ms-wmv",
    ".wmx"     => "video/x-ms-wmx",
    ".woff"    => "font/woff",
    ".woff2"   => "font/woff2",
    ".wrl"     => "model/vrml",
    ".wsdl"    => "application/wsdl+xml",
    ".xbm"     => "image/x-xbitmap",
    ".xhtml"   => "application/xhtml+xml",
    ".xls"     => "application/vnd.ms-excel",
    ".xlsx"    => "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
    ".xml"     => "application/xml",
    ".xpm"     => "image/x-xpixmap",
    ".xsl"     => "application/xml",
    ".xslt"    => "application/xslt+xml",
    ".yaml"    => "text/yaml",
    ".yml"     => "text/yaml",
    ".zip"     => "application/zip",
};

my $fallback = sub { };

sub mime_type {
    my($class, $file) = @_;
    $file =~ /(\.[a-zA-Z0-9\-]+)$/ or return;
    $MIME_TYPES->{lc $1} || $fallback->(lc $1);
}

sub add_type {
    my $class = shift;
    while (my($ext, $type) = splice @_, 0, 2) {
        $MIME_TYPES->{lc $ext} = $type;
    }
}

sub set_fallback {
    my($class, $cb) = @_;
    $fallback = $cb;
}

1;

__END__

=head1 NAME

Plack::MIME - MIME type registry

=head1 SYNOPSIS

  use Plack::MIME;

  my $mime = Plack::MIME->mime_type(".png"); # image/png

  # register new type(s)
  Plack::MIME->add_type(".foo" => "application/x-foo");

  # Use MIME::Types as a fallback
  use MIME::Types 'by_suffix';
  Plack::MIME->set_fallback(sub { (by_suffix $_[0])[0] });

=head1 DESCRIPTION

Plack::MIME is a simple MIME type registry for Plack applications. The
selection of MIME types is based on Rack's Rack::Mime module.

=head1 SEE ALSO

L<Rack::Mime|https://github.com/rack/rack/blob/master/lib/rack/mime.rb> L<MIME::Types>

=cut
