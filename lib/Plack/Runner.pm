package Plack::Runner;
use strict;
use warnings;
use File::Basename;
use Getopt::Long;
use Plack::Loader;
use Plack::Util;
use Try::Tiny;

sub new {
    my $class = shift;
    bless {
        port => 5000,
        env  => 'development',
        includes => [],
        modules  => [],
        watch    => [],
        @_,
    }, $class;
}

# delay the build process for reloader
sub build(&;$) {
    my $block = shift;
    my $app   = shift || sub { };
    return sub { $block->($app->()) };
}

sub parse_options {
    my $self = shift;

    local @ARGV = @_;

    # From 'prove': Allow cuddling the paths with -I and -M
    @ARGV = map { /^(-[IM])(.+)/ ? ($1,$2) : $_ } @ARGV;

    Getopt::Long::Configure("no_ignore_case", "pass_through");
    GetOptions(
        "a|app=s"      => \$self->{app},
        "o|host=s"     => \$self->{host},
        "p|port=i"     => \$self->{port},
        "s|server=s"   => \$self->{server},
        "E|env=s"      => \$self->{env},
        "e=s"          => \$self->{eval},
        'I=s@'         => $self->{includes},
        'M=s@'         => $self->{modules},
        'r|reload'     => sub { $self->{reload} = 1 },
        'R|Reload=s'   => sub { push @{$self->{watch}}, split ",", $_[1] },
        "h|help",      => \$self->{help},
    );

    if ($self->{help}) {
        require Pod::Usage;
        Pod::Usage::pod2usage(0);
    }

    lib->import(@{$self->{includes}}) if @{$self->{includes}};

    if ($self->{eval}) {
        push @{$self->{modules}}, 'Plack::Builder';
    }

    for (@{$self->{modules}}) {
        my($module, @import) = split /[=,]/;
        eval "require $module" or die $@;
        $module->import(@import);
    }

    my(@options, @argv);
    while (defined($_ = shift @ARGV)) {
        if (s/^--?//) {
            my @v = split '=', $_, 2;
            $v[0] =~ tr/-/_/;
            if (@v == 2) {
                push @options, @v;
            } else {
                push @options, @v, shift @ARGV;
            }
        } else {
            push @argv, $_;
        }
    }

    push @options, host => $self->{host}, port => $self->{port};
    $self->{options} = \@options;
    $self->{argv}    = \@argv;
}

sub run {
    my $self = shift;

    unless (ref $self) {
        $self = $self->new;
        $self->parse_options(@_);
        return $self->run;
    }

    my @args = @_ ? @_ : @{$self->{argv}};

    my $psgi = $self->{app} || $args[0] || "app.psgi";

    my $app = $self->{eval}       ? build { no strict; no warnings; eval $self->{eval} or die $@ }
            : ref $psgi eq 'CODE' ? sub   { $psgi }
            :                       build { Plack::Util::load_psgi $psgi };

    if ($self->{env} eq 'development') {
        require Plack::Middleware::StackTrace;
        require Plack::Middleware::AccessLog;
        $app = build { Plack::Middleware::StackTrace->wrap($_[0]) } $app;
        unless ($ENV{GATEWAY_INTERFACE}) {
            $app = build { Plack::Middleware::AccessLog->wrap($_[0], logger => sub { print STDERR @_ }) } $app;
        }

        push @{$self->{options}}, server_ready => sub {
            my($args) = @_;
            my $name = $args->{server_software} || ref($args); # $args is $server
            print STDERR "$name: Accepting connections at http://$args->{host}:$args->{port}/\n";
        };
    }

    my $loader;

    if ($self->{reload} or @{$self->{watch}}) {
        if ($self->{reload}) {
            push @{$self->{watch}}, $self->{eval} ? "lib" : ( File::Basename::dirname($psgi) . "/lib", $psgi );
        }
        warn "plackup: Watching ", join(", ", @{$self->{watch}}), " for changes\n";
        require Plack::Loader::Reloadable;
        $loader = Plack::Loader::Reloadable->new($self->{watch});
    } else {
        $loader = 'Plack::Loader';
        $app = $app->();
    }

    my $server = $self->{server} ? $loader->load($self->{server}, @{$self->{options}}) : $loader->auto(@{$self->{options}});
    $server->run($app);
}


1;

__END__

=head1 NAME

Plack::Runner - plackup core

=head1 SYNOPSIS

  # Your bootstrap script
  use Plack::Runner;
  my $app = sub { ... };

  my $runner = Plack::Runner->new;
  $runner->parse_options(@ARGV);
  $runner->run($app);

=head1 DESCRIPTION

Plack::Runner is the core of L<plackup> runner script. You can create
your own frontend to run your application or framework, munge command
line options and pass that to C<run> method of this class.

C<run> method does exactly the same thing as the L<plackup> script
does, but one notable addition is that you can pass a PSGI application
code reference directly with C<--app> option, rather than via C<.psgi>
file path or with C<-e> switch. This would be useful if you want to
make an installable PSGI application.

Also, when C<-h> or C<--help> switch is passed, the usage text is
automatically extracted from your own script using L<Pod::Usage>.

=head1 NOTES

Do not directly call this module from your C<.psgi>, since that makes
your PSGI application unnecesarily depend on L<plackup> and won't run
other backends like L<Plack::Server::Apache2> or mod_psgi.

If you I<really> want to make your C<.psgi> runnable as a standalone
script, you can do this:

  # foo.psgi
  if (__FILE__ eq $0) {
      require Plack::Runner;
      Plack::Runner->run(@ARGV, $0);
  }

  # This should always come last
  my $app = sub { ... };

=head1 SEE ALSO

L<plackup>

=cut


