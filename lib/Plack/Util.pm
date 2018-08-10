package Plack::Util;
use strict;
use Carp ();
use Scalar::Util;
use IO::Handle;
use overload ();
use File::Spec ();

sub TRUE()  { 1==1 }
sub FALSE() { !TRUE }

# there does not seem to be a relevant RT or perldelta entry for this
use constant _SPLICE_SAME_ARRAY_SEGFAULT => $] < '5.008007';

sub load_class {
    my($class, $prefix) = @_;

    if ($prefix) {
        unless ($class =~ s/^\+// || $class =~ /^$prefix/) {
            $class = "$prefix\::$class";
        }
    }

    my $file = $class;
    $file =~ s!::!/!g;
    require "$file.pm"; ## no critic

    return $class;
}

sub is_real_fh ($) {
    my $fh = shift;

    {
        no warnings 'uninitialized';
        return FALSE if -p $fh or -c _ or -b _;
    }

    my $reftype = Scalar::Util::reftype($fh) or return;
    if (   $reftype eq 'IO'
        or $reftype eq 'GLOB' && *{$fh}{IO}
    ) {
        # if it's a blessed glob make sure to not break encapsulation with
        # fileno($fh) (e.g. if you are filtering output then file descriptor
        # based operations might no longer be valid).
        # then ensure that the fileno *opcode* agrees too, that there is a
        # valid IO object inside $fh either directly or indirectly and that it
        # corresponds to a real file descriptor.
        my $m_fileno = $fh->fileno;
        return FALSE unless defined $m_fileno;
        return FALSE unless $m_fileno >= 0;

        my $f_fileno = fileno($fh);
        return FALSE unless defined $f_fileno;
        return FALSE unless $f_fileno >= 0;
        return TRUE;
    } else {
        # anything else, including GLOBS without IO (even if they are blessed)
        # and non GLOB objects that look like filehandle objects cannot have a
        # valid file descriptor in fileno($fh) context so may break.
        return FALSE;
    }
}

sub set_io_path {
    my($fh, $path) = @_;
    bless $fh, 'Plack::Util::IOWithPath';
    $fh->path($path);
}

sub content_length {
    my $body = shift;

    return unless defined $body;

    if (ref $body eq 'ARRAY') {
        my $cl = 0;
        for my $chunk (@$body) {
            $cl += length $chunk;
        }
        return $cl;
    } elsif ( is_real_fh($body) ) {
        return (-s $body) - tell($body);
    }

    return;
}

sub foreach {
    my($body, $cb) = @_;

    if (ref $body eq 'ARRAY') {
        for my $line (@$body) {
            $cb->($line) if length $line;
        }
    } else {
        local $/ = \65536 unless ref $/;
        while (defined(my $line = $body->getline)) {
            $cb->($line) if length $line;
        }
        $body->close;
    }
}

sub class_to_file {
    my $class = shift;
    $class =~ s!::!/!g;
    $class . ".pm";
}

sub _load_sandbox {
    my $_file = shift;

    my $_package = $_file;
    $_package =~ s/([^A-Za-z0-9_])/sprintf("_%2x", unpack("C", $1))/eg;

    local $0 = $_file; # so FindBin etc. works
    local @ARGV = ();  # Some frameworks might try to parse @ARGV

    return eval sprintf <<'END_EVAL', $_package;
package Plack::Sandbox::%s;
{
    my $app = do $_file;
    if ( !$app && ( my $error = $@ || $! )) { die $error; }
    $app;
}
END_EVAL
}

sub load_psgi {
    my $stuff = shift;

    local $ENV{PLACK_ENV} = $ENV{PLACK_ENV} || 'development';

    my $file = $stuff =~ /^[a-zA-Z0-9\_\:]+$/ ? class_to_file($stuff) : File::Spec->rel2abs($stuff);
    my $app = _load_sandbox($file);
    die "Error while loading $file: $@" if $@;

    return $app;
}

sub run_app($$) {
    my($app, $env) = @_;

    return eval { $app->($env) } || do {
        my $body = "Internal Server Error";
        $env->{'psgi.errors'}->print($@);
        [ 500, [ 'Content-Type' => 'text/plain', 'Content-Length' => length($body) ], [ $body ] ];
    };
}

sub headers {
    my $headers = shift;
    inline_object(
        iter   => sub { header_iter($headers, @_) },
        get    => sub { header_get($headers, @_) },
        set    => sub { header_set($headers, @_) },
        push   => sub { header_push($headers, @_) },
        exists => sub { header_exists($headers, @_) },
        remove => sub { header_remove($headers, @_) },
        headers => sub { $headers },
    );
}

sub header_iter {
    my($headers, $code) = @_;

    my @headers = @$headers; # copy
    while (my($key, $val) = splice @headers, 0, 2) {
        $code->($key, $val);
    }
}

sub header_get {
    my($headers, $key) = (shift, lc shift);

    return () if not @$headers;

    my $i = 0;

    if (wantarray) {
        return map {
            $key eq lc $headers->[$i++] ? $headers->[$i++] : ++$i && ();
        } 1 .. @$headers/2;
    }

    while ($i < @$headers) {
        return $headers->[$i+1] if $key eq lc $headers->[$i];
        $i += 2;
    }

    ();
}

sub header_set {
    my($headers, $key, $val) = @_;

    @$headers = ($key, $val), return if not @$headers;

    my ($i, $_key) = (0, lc $key);

    # locate and change existing header
    while ($i < @$headers) {
        $headers->[$i+1] = $val, last if $_key eq lc $headers->[$i];
        $i += 2;
    }

    if ($i > $#$headers) { # didn't find it?
        push @$headers, $key, $val;
        return;
    }

    $i += 2; # found and changed it; so, first, skip that pair

    return if $i > $#$headers; # anything left?

    # yes... so do the same thing as header_remove
    # but for the tail of the array only, starting at $i

    my $keep;
    my @keep = grep {
        $_ & 1 ? $keep : ($keep = $_key ne lc $headers->[$_]);
    } $i .. $#$headers;

    my $remainder = @$headers - $i;
    return if @keep == $remainder; # if we're not changing anything...

    splice @$headers, $i, $remainder, ( _SPLICE_SAME_ARRAY_SEGFAULT
        ? @{[ @$headers[@keep] ]} # force different source array
        :     @$headers[@keep]
    );
    ();
}

sub header_push {
    my($headers, $key, $val) = @_;
    push @$headers, $key, $val;
}

sub header_exists {
    my($headers, $key) = (shift, lc shift);

    my $check;
    for (@$headers) {
        return 1 if ($check = not $check) and $key eq lc;
    }

    return !1;
}

sub header_remove {
    my($headers, $key) = (shift, lc shift);

    return if not @$headers;

    my $keep;
    my @keep = grep {
        $_ & 1 ? $keep : ($keep = $key ne lc $headers->[$_]);
    } 0 .. $#$headers;

    @$headers = @$headers[@keep] if @keep < @$headers;
    ();
}

sub status_with_no_entity_body {
    my $status = shift;
    return $status < 200 || $status == 204 || $status == 304;
}

sub encode_html {
    my $str = shift;
    $str =~ s/&/&amp;/g;
    $str =~ s/>/&gt;/g;
    $str =~ s/</&lt;/g;
    $str =~ s/"/&quot;/g;
    $str =~ s/'/&#39;/g;
    return $str;
}

sub inline_object {
    my %args = @_;
    bless \%args, 'Plack::Util::Prototype';
}

sub response_cb {
    my($res, $cb) = @_;

    my $body_filter = sub {
        my($cb, $res) = @_;
        my $filter_cb = $cb->($res);
        # If response_cb returns a callback, treat it as a $body filter
        if (defined $filter_cb && ref $filter_cb eq 'CODE') {
            Plack::Util::header_remove($res->[1], 'Content-Length');
            if (defined $res->[2]) {
                if (ref $res->[2] eq 'ARRAY') {
                    for my $line (@{$res->[2]}) {
                        $line = $filter_cb->($line);
                    }
                    # Send EOF.
                    my $eof = $filter_cb->( undef );
                    push @{ $res->[2] }, $eof if defined $eof;
                } else {
                    my $body    = $res->[2];
                    my $getline = sub { $body->getline };
                    $res->[2] = Plack::Util::inline_object
                        getline => sub { $filter_cb->($getline->()) },
                        close => sub { $body->close };
                }
            } else {
                return $filter_cb;
            }
        }
    };

    if (ref $res eq 'ARRAY') {
        $body_filter->($cb, $res);
        return $res;
    } elsif (ref $res eq 'CODE') {
        return sub {
            my $respond = shift;
            my $cb = $cb;  # To avoid the nested closure leak for 5.8.x
            $res->(sub {
                my $res = shift;
                my $filter_cb = $body_filter->($cb, $res);
                if ($filter_cb) {
                    my $writer = $respond->($res);
                    if ($writer) {
                        return Plack::Util::inline_object
                            write => sub { $writer->write($filter_cb->(@_)) },
                            close => sub {
                                my $chunk = $filter_cb->(undef);
                                $writer->write($chunk) if defined $chunk;
                                $writer->close;
                            };
                    }
                } else {
                    return $respond->($res);
                }
            });
        };
    }

    return $res;
}

package Plack::Util::Prototype;

our $AUTOLOAD;
sub can {
    return $_[0]->{$_[1]} if Scalar::Util::blessed($_[0]);
    goto &UNIVERSAL::can;
}

sub AUTOLOAD {
    my $self = shift;
    my $attr = $AUTOLOAD;
    $attr =~ s/.*://;
    if (ref($self->{$attr}) eq 'CODE') {
        $self->{$attr}->(@_);
    } else {
        Carp::croak(qq/Can't locate object method "$attr" via package "Plack::Util::Prototype"/);
    }
}

sub DESTROY { }

package Plack::Util::IOWithPath;
use parent qw(IO::Handle);

sub path {
    my $self = shift;
    if (@_) {
        ${*$self}{+__PACKAGE__} = shift;
    }
    ${*$self}{+__PACKAGE__};
}

package Plack::Util;

1;

__END__

=head1 NAME

Plack::Util - Utility subroutines for Plack server and framework developers

=head1 FUNCTIONS

=over 4

=item TRUE, FALSE

  my $true  = Plack::Util::TRUE;
  my $false = Plack::Util::FALSE;

Utility constants to include when you specify boolean variables in C<$env> hash (e.g. C<psgi.multithread>).

=item load_class

  my $class = Plack::Util::load_class($class [, $prefix ]);

Constructs a class name and C<require> the class. Throws an exception
if the .pm file for the class is not found, just with the built-in
C<require>.

If C<$prefix> is set, the class name is prepended to the C<$class>
unless C<$class> begins with C<+> sign, which means the class name is
already fully qualified.

  my $class = Plack::Util::load_class("Foo");                   # Foo
  my $class = Plack::Util::load_class("Baz", "Foo::Bar");       # Foo::Bar::Baz
  my $class = Plack::Util::load_class("+XYZ::ZZZ", "Foo::Bar"); # XYZ::ZZZ

Note that this function doesn't validate (or "sanitize") the passed
string, hence if you pass a user input to this function (which is an
insecure thing to do in the first place) it might lead to unexpected
behavior of loading files outside your C<@INC> path. If you want a
generic module loading function, you should check out CPAN modules
such as L<Module::Runtime>.

=item is_real_fh

  if ( Plack::Util::is_real_fh($fh) ) { }

returns true if a given C<$fh> is a real file handle that has a file
descriptor. It returns false if C<$fh> is PerlIO handle that is not
really related to the underlying file etc.

=item content_length

  my $cl = Plack::Util::content_length($body);

Returns the length of content from body if it can be calculated. If
C<$body> is an array ref it's a sum of length of each chunk, if
C<$body> is a real filehandle it's a remaining size of the filehandle,
otherwise returns undef.

=item set_io_path

  Plack::Util::set_io_path($fh, "/path/to/foobar.txt");

Sets the (absolute) file path to C<$fh> filehandle object, so you can
call C<< $fh->path >> on it. As a side effect C<$fh> is blessed to an
internal package but it can still be treated as a normal file
handle.

This module doesn't normalize or absolutize the given path, and is
intended to be used from Server or Middleware implementations. See
also L<IO::File::WithPath>.

=item foreach

  Plack::Util::foreach($body, $cb);

Iterate through I<$body> which is an array reference or
IO::Handle-like object and pass each line (which is NOT really
guaranteed to be a I<line>) to the callback function.

It internally sets the buffer length C<$/> to 65536 in case it reads
the binary file, unless otherwise set in the caller's code.

=item load_psgi

  my $app = Plack::Util::load_psgi $psgi_file_or_class;

Load C<app.psgi> file or a class name (like C<MyApp::PSGI>) and
require the file to get PSGI application handler. If the file can't be
loaded (e.g. file doesn't exist or has a perl syntax error), it will
throw an exception.

Since version 1.0006, this function would not load PSGI files from
include paths (C<@INC>) unless it looks like a class name that only
consists of C<[A-Za-z0-9_:]>. For example:

  Plack::Util::load_psgi("app.psgi");          # ./app.psgi
  Plack::Util::load_psgi("/path/to/app.psgi"); # /path/to/app.psgi
  Plack::Util::load_psgi("MyApp::PSGI");       # MyApp/PSGI.pm from @INC

B<Security>: If you give this function a class name or module name
that is loadable from your system, it will load the module. This could
lead to a security hole:

  my $psgi = ...; # user-input: consider "Moose"
  $app = Plack::Util::load_psgi($psgi); # this would lead to 'require "Moose.pm"'!

Generally speaking, passing an external input to this function is
considered very insecure. If you really want to do that, validate that
a given file name contains dots (like C<foo.psgi>) and also turn it
into a full path in your caller's code.

=item run_app

  my $res = Plack::Util::run_app $app, $env;

Runs the I<$app> by wrapping errors with I<eval> and if an error is
found, logs it to C<< $env->{'psgi.errors'} >> and returns the
template 500 Error response.

=item header_get, header_exists, header_set, header_push, header_remove

  my $hdrs = [ 'Content-Type' => 'text/plain' ];

  my $v = Plack::Util::header_get($hdrs, $key); # First found only
  my @v = Plack::Util::header_get($hdrs, $key);
  my $bool = Plack::Util::header_exists($hdrs, $key);
  Plack::Util::header_set($hdrs, $key, $val);   # overwrites existent header
  Plack::Util::header_push($hdrs, $key, $val);
  Plack::Util::header_remove($hdrs, $key);

Utility functions to manipulate PSGI response headers array
reference. The methods that read existent header value handles header
name as case insensitive.

  my $hdrs = [ 'Content-Type' => 'text/plain' ];
  my $v = Plack::Util::header_get($hdrs, 'content-type'); # 'text/plain'

=item headers

  my $headers = [ 'Content-Type' => 'text/plain' ];

  my $h = Plack::Util::headers($headers);
  $h->get($key);
  if ($h->exists($key)) { ... }
  $h->set($key => $val);
  $h->push($key => $val);
  $h->remove($key);
  $h->headers; # same reference as $headers

Given a header array reference, returns a convenient object that has
an instance methods to access C<header_*> functions with an OO
interface. The object holds a reference to the original given
C<$headers> argument and updates the reference accordingly when called
write methods like C<set>, C<push> or C<remove>. It also has C<headers>
method that would return the same reference.

=item status_with_no_entity_body

  if (status_with_no_entity_body($res->[0])) { }

Returns true if the given status code doesn't have any Entity body in
HTTP response, i.e. it's 100, 101, 204 or 304.

=item inline_object

  my $o = Plack::Util::inline_object(
      write => sub { $h->push_write(@_) },
      close => sub { $h->push_shutdown },
  );
  $o->write(@stuff);
  $o->close;

Creates an instant object that can react to methods passed in the
constructor. Handy to create when you need to create an IO stream
object for input or errors.

=item encode_html

  my $encoded_string = Plack::Util::encode_html( $string );

Entity encodes C<<>, C<< > >>, C<&>, C<"> and C<'> in the input string
and returns it.

=item response_cb

See L<Plack::Middleware/RESPONSE CALLBACK> for details.

=back

=cut



