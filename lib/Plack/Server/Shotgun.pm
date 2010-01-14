package Plack::Server::Shotgun;
use strict;
use Storable;
use HTTP::Server::PSGI;
use Try::Tiny;

sub new {
    my($class, %args) = @_;
    bless { args => \%args }, $class;
}

sub run_with_reload {
    my($self, $builder) = @_;
    HTTP::Server::PSGI->new(%{$self->{args}})->run($self->_app($builder));
}

sub _app {
    my($self, $builder) = @_;

    return sub {
        my $env = shift;

        pipe my $read, my $write;

        my $pid = fork;
        if ($pid > 0) {
            # parent
            close $write;
            my $res = Storable::thaw(join '', <$read>);
            close $read;
            waitpid($pid, 0);

            return $res;
        } else {
            # child
            close $read;

            # TODO buffer streaming
            my $res = $builder->()->($env);

            my @body;
            Plack::Util::foreach($res->[2], sub { push @body, $_[0] });
            $res->[2] = \@body;

            print {$write} Storable::freeze($res);
            close $write;
            exit;
        }
    };
}

sub run { die "Run this by `plackup -r -s Shotgun`" }

1;

__END__

=head1 NAME

Plack::Server::Shotgun - forking implementation of plackup

=head1 SYNOPSIS

  plackup -r -s Shotgun

=head1 DESCRIPTIOM

Shotgun server delays the compilation and execution of your
application until the runtime. When a new request comes in, this forks
a new child, compiles your code and runs the application.

This should be an ultimate alternative solution when reloading with
L<Plack::Middleware::Refresh> doesn't work, or plackup's default C<-r>
filesystem watcher causes problems. I can imagine this is useulf for
applications which expects their application is only evaluated once
(like in-file templates) or on operating systems with broken fork
implementation, etc.

This is much like good old CGI's fork and run but you don't need a web
server, and there's a benefit of preloading modules that are not
likely to change. For instance if you develop a web application using
Moose and DBIx::Class,

  plackup -MMoose -MDBIx::Class -r -s Shotgun yourapp.psgi

would preload those modules and only re-evaluates your code in every
request.

=head1 AUTHOR

Tatsuhiko Miyagawa with an inspiration from L<http://github.com/rtomayko/shotgun>

=head1 SEE ALSO

L<plackup>

=cut
