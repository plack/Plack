package Plack::App::WrapCGI;
use strict;
use warnings;
use parent qw(Plack::Component);
use Plack::Util::Accessor qw(script execute _app);
use File::Spec;
use CGI::Emulate::PSGI;
use CGI::Compile;
use Carp;
use POSIX ":sys_wait_h";

sub prepare_app {
    my $self = shift;
    my $script = $self->script
        or croak "'script' is not set";

    $script = File::Spec->rel2abs($script);

    if ($self->execute) {
        my $app = sub {
            my $env = shift;

            pipe( my $stdoutr, my $stdoutw );
            pipe( my $stdinr,  my $stdinw );


            my $pid = fork();
            Carp::croak("fork failed: $!") unless defined $pid;


            if ($pid == 0) { # child
                local $SIG{__DIE__} = sub {
                    print STDERR @_;
                    exit(1);
                };

                close $stdoutr;
                close $stdinw;

                local %ENV = (%ENV, CGI::Emulate::PSGI->emulate_environment($env));

                open( STDOUT, ">&=" . fileno($stdoutw) )
                  or Carp::croak "Cannot dup STDOUT: $!";
                open( STDIN, "<&=" . fileno($stdinr) )
                  or Carp::croak "Cannot dup STDIN: $!";

                chdir(File::Basename::dirname($script));
                exec($script) or Carp::croak("cannot exec: $!");

                exit(2);
            }

            close $stdoutw;
            close $stdinr;

            syswrite($stdinw, do {
                local $/;
                my $fh = $env->{'psgi.input'};
                <$fh>;
            });
            # close STDIN so child will stop waiting
            close $stdinw;

            my $res = '';
            while (waitpid($pid, WNOHANG) <= 0) {
                $res .= do { local $/; <$stdoutr> };
            }
            $res .= do { local $/; <$stdoutr> };

            if (POSIX::WIFEXITED($?)) {
                return CGI::Parse::PSGI::parse_cgi_output(\$res);
            } else {
                Carp::croak("Error at run_on_shell CGI: $!");
            }
        };
        $self->_app($app);
    } else {
        my $sub = CGI::Compile->compile($script);
        my $app = CGI::Emulate::PSGI->handler($sub);

        $self->_app($app);
    }
}

sub call {
    my($self, $env) = @_;
    $self->_app->($env);
}

1;

__END__

=head1 NAME

Plack::App::WrapCGI - Compiles a CGI script as PSGI application

=head1 SYNOPSIS

  use Plack::App::WrapCGI;

  my $app = Plack::App::WrapCGI->new(script => "/path/to/script.pl")->to_app;

  # if you want to execute as a real CGI script
  my $app = Plack::App::WrapCGI->new(script => "/path/to/script.rb", execute => 1)->to_app;

=head1 DESCRIPTION

Plack::App::WrapCGI compiles a CGI script into a PSGI application
using L<CGI::Compile> and L<CGI::Emulate::PSGI>, and runs it with any
PSGI server as a PSGI application.

See also L<Plack::App::CGIBin> if you have a directory that contains a
lot of CGI scripts and serve them like Apache's mod_cgi.

=head1 METHODS

=over 4

=item new

  my $app = Plack::App::WrapCGI->new(%args);

Creates a new PSGI application using the given script. I<%args> has two
parameters:

=over 8

=item script

The path to a CGI-style program. This is a required parameter.

=item execute

An optional parameter. When set to a true value, this app will run the script
with a CGI-style C<fork>/C<exec> model. Note that you may run programs written
in other languages with this approach.

=back

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 SEE ALSO

L<Plack::App::CGIBin>

=cut
