package Plack::Test::Adopt::Catalyst;
use strict;
use Catalyst::Engine::PSGI;
BEGIN { $ENV{CATALYST_ENGINE} = 'PSGI' };

use Class::MOP;
use Test::TCP;
use App::Prove;

sub import {
    my($self, $class) = @_;

    my $caller = caller;
    no strict;
    *{"$caller\::runtests"} = make_runtests($class);
}

sub make_runtests {
    my $class = shift;

    Class::MOP::load_class($class);
    return sub {
        my @tests = @_;

        my $app = sub { $class->run(@_) };
        test_tcp(
            client => sub {
                my $port = shift;
                $ENV{CATALYST_SERVER} = "http://127.0.0.1:$port/";

                my $prove = App::Prove->new;
                $prove->process_args(@tests);
                $prove->run;
            },
            server => sub {
                my $port = shift;

                # TODO: We need auto-selector
                use Plack::Impl::ServerSimple;
                my $server = Plack::Impl::ServerSimple->new($port);
                $server->host("127.0.0.1");
                $server->psgi_app($app);
                $server->run;
            },
        );
    };
}

1;

__END__

=head1 NAME

Plack::Test::Adopt::Catalyst - Run Catalyst::Test based tests against Plack implementations

=head1 SYNOPSIS

  perl -MPlack::Test::Adopt::Catalyst=TestApp -e 'runtests @ARGV' *.t

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Catalyst::Test> L<Plack::Test>

=cut
