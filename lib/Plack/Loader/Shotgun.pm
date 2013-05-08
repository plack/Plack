package Plack::Loader::Shotgun;
use strict;
use parent qw(Plack::Loader);
use Storable;
use Try::Tiny;
use Plack::Middleware::BufferedStreaming;

die <<DIE if $^O eq 'MSWin32' && !$ENV{PLACK_SHOTGUN_MEMORY_LEAK};

Shotgun loader uses fork(2) system call to create a fresh Perl interpreter, that is known to not work
properly in a fork-emulation layer on Windows and cause huge memory leaks.

If you're aware of this and still want to run the loader, run it with the environment variable
PLACK_SHOTGUN_MEMORY_LEAK on.

DIE

sub preload_app {
    my($self, $builder) = @_;
    $self->{builder} = sub { Plack::Middleware::BufferedStreaming->wrap($builder->()) };
}

sub run {
    my($self, $server) = @_;

    my $app = sub {
        my $env = shift;

        pipe my $read, my $write;

        my $pid = fork;
        if ($pid) {
            # parent
            close $write;
            my $res = Storable::thaw(join '', <$read>);
            close $read;
            waitpid($pid, 0);

            return $res;
        } else {
            # child
            close $read;

            my $res;
            try {
                $env->{'psgi.streaming'} = 0;
                $res = $self->{builder}->()->($env);
                my @body;
                Plack::Util::foreach($res->[2], sub { push @body, $_[0] });
                $res->[2] = \@body;
            } catch {
                $env->{'psgi.errors'}->print($_);
                $res = [ 500, [ "Content-Type", "text/plain" ], [ "Internal Server Error" ] ];
            };

            print {$write} Storable::freeze($res);
            close $write;
            exit;
        }
    };

    $server->run($app);
}

1;

__END__

=head1 NAME

Plack::Loader::Shotgun - forking implementation of plackup

=head1 SYNOPSIS

  plackup -L Shotgun

=head1 DESCRIPTION

Shotgun loader delays the compilation and execution of your
application until the runtime. When a new request comes in, this forks
a new child, compiles your code and runs the application.

This should be an ultimate alternative solution when reloading with
L<Plack::Middleware::Refresh> doesn't work, or plackup's default C<-r>
filesystem watcher causes problems. I can imagine this is useful for
applications which expects their application is only evaluated once
(like in-file templates) or on operating systems with broken fork
implementation, etc.

This is much like good old CGI's fork and run but you don't need a web
server, and there's a benefit of preloading modules that are not
likely to change. For instance if you develop a web application using
Moose and DBIx::Class,

  plackup -MMoose -MDBIx::Class -L Shotgun yourapp.psgi

would preload those modules and only re-evaluates your code in every
request.

=head1 AUTHOR

Tatsuhiko Miyagawa with an inspiration from L<http://github.com/rtomayko/shotgun>

=head1 SEE ALSO

L<plackup>

=cut
