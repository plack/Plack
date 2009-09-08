package Plack::Test::Adopt::Catalyst;
use strict;
use Catalyst::Engine::PSGI;
BEGIN { $ENV{CATALYST_ENGINE} = 'PSGI' };

use Class::MOP;
use Test::TCP;
use App::Prove;
use Plack::Impl;

sub import {
    my($self, $class) = @_;

    my $caller = caller;
    no strict; ## no critic
    *{"$caller\::runtests"} = make_runtests($class);
}

sub make_runtests {
    my $class = shift;

    return sub {
        my @tests = @_;

        my %apps2tests = analyze_tests($class, @tests);
        while (my($app_class, $tests) = each %apps2tests) {
            warn "Testing $app_class\n";
            Class::MOP::load_class($app_class);
            my $app = sub { $app_class->run(@_) };
            test_tcp(
                client => sub {
                    my $port = shift;
                    $ENV{CATALYST_SERVER} = "http://127.0.0.1:$port/";

                    my $p = App::Prove->new;
                    $p->process_args(@$tests);
                    $p->run;
                },
                server => sub {
                    my $port = shift;
                    Plack::Impl->auto(port => $port, host => "127.0.0.1")->run($app);
                },
            );
        }
    };
}

sub analyze_tests {
    my($class, @tests) = @_;

    my %map;
    for my $test (@tests) {
        my $cat_app_class = test_app_for($test) || $class;
        push @{$map{$cat_app_class}}, $test;
    }

    return %map;
}

sub test_app_for {
    my $test = shift;

    open my $fh, "<", $test or return;
    while (<$fh>) {
        m@^\s*use Catalyst::Test (?:q[qw]?)?[/'"\(]?\s*([a-zA-Z0-9:]+)@
            and return $1;
    }

    return;
}

1;

__END__

=head1 NAME

Plack::Test::Adopt::Catalyst - Run Catalyst::Test based tests against Plack implementations

=head1 SYNOPSIS

  env PSGI_PLACK_IMPL=Mojo \
    perl -MPlack::Test::Adopt::Catalyst=TestApp -e 'runtests @ARGV' *.t

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Catalyst::Test> L<Plack::Test>

=cut
