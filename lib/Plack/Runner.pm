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
    bless {}, $class;
}

# delay the build process for reloader
sub build(&;$) {
    my $block = shift;
    my $app   = shift || sub { };
    return sub { $block->($app->()) };
}

sub run {
    my $self = shift;
    $self = $self->new unless ref $self;

    local @ARGV = @_;

    my $psgi;
    my $eval;
    my $host;
    my $port   = 5000;
    my $env    = "development";
    my $help   = 0;
    my $backend;
    my @reload;
    my $reload;
    my @includes;
    my @modules;

    # From 'prove': Allow cuddling the paths with -I and -M
    @ARGV = map { /^(-[IM])(.+)/ ? ($1,$2) : $_ } @ARGV;

    Getopt::Long::Configure("no_ignore_case", "pass_through");
    GetOptions(
        "a|app=s"      => \$psgi,
        "o|host=s"     => \$host,
        "p|port=i"     => \$port,
        "s|server=s"   => \$backend,
        "i|impl=s"     => sub { warn "-i is deprecated. Use -s instead\n"; $backend = $_[1] },
        "E|env=s"      => \$env,
        "e=s"          => \$eval,
        'I=s@'         => \@includes,
        'M=s@'         => \@modules,
        'r|reload'     => sub { $reload = 1 },
        'R|Reload=s'   => sub { push @reload, split ",", $_[1] },
        "h|help",      => \$help,
    );

    if ($help) {
        require Pod::Usage;
        Pod::Usage::pod2usage(0);
    }

    lib->import(@includes) if @includes;

    if ($eval) {
        push @modules, 'Plack::Builder';
    }

    for (@modules) {
        my($module, @import) = split /[=,]/;
        eval "require $module" or die $@;
        $module->import(@import);
    }

    my(@options, @argv);
    while (defined($_ = shift @ARGV)) {
        if (s/^--//) {
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

    push @options, host => $host, port => $port;

    $psgi ||= $argv[0] || "app.psgi";
    my $app = $eval               ? build { no strict; no warnings; eval $eval or die $@ }
            : ref $psgi eq 'CODE' ? sub   { $psgi }
            :                       build { Plack::Util::load_psgi $psgi };

    if ($env eq 'development') {
        require Plack::Middleware::StackTrace;
        require Plack::Middleware::AccessLog;
        $app = build { Plack::Middleware::StackTrace->wrap($_[0]) } $app;
        $app = build { Plack::Middleware::AccessLog->wrap($_[0], logger => sub { print STDERR @_ }) } $app;
    }

    my $loader;

    if ($reload or @reload) {
        if ($reload) {
            push @reload, $eval ? "lib" : ( File::Basename::dirname($psgi) . "/lib", $psgi );
        }
        warn "plackup: Watching ", join(", ", @reload), " for changes\n";
        require Plack::Loader::Reloadable;
        $loader = Plack::Loader::Reloadable->new(\@reload);
    } else {
        $loader = 'Plack::Loader';
        $app = $app->();
    }

    my $server = $backend ? $loader->load($backend, @options) : $loader->auto(@options);
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

  Plack::Runner->run('--app' => $app, @ARGV);

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


