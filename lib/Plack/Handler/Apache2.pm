package Plack::Handler::Apache2;
use strict;
use warnings;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::RequestUtil;
use Apache2::Response;
use Apache2::Const -compile => qw(OK);
use Apache2::Log;
use APR::Table;
use IO::Handle;
use Plack::Util;
use Scalar::Util;
use URI;
use URI::Escape;

my %apps; # psgi file to $app mapping

sub new { bless {}, shift }

sub preload {
    my $class = shift;
    for my $app (@_) {
        $class->load_app($app);
    }
}

sub load_app {
    my($class, $app) = @_;
    return $apps{$app} ||= do {
        # Trick Catalyst, CGI.pm, CGI::Cookie and others that check
        # for $ENV{MOD_PERL}.
        #
        # Note that we delete it instead of just localizing
        # $ENV{MOD_PERL} because some users may check if the key
        # exists, and we do it this way because "delete local" is new
        # in 5.12:
        # http://perldoc.perl.org/5.12.0/perldelta.html#delete-local
        local $ENV{MOD_PERL};
        delete $ENV{MOD_PERL};

        Plack::Util::load_psgi $app;
    };
}

sub call_app {
    my ($class, $r, $app) = @_;

    $r->subprocess_env; # let Apache create %ENV for us :)

    my $env = {
        %ENV,
        'psgi.version'           => [ 1, 1 ],
        'psgi.url_scheme'        => ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'             => $r,
        'psgi.errors'            => *STDERR,
        'psgi.multithread'       => Plack::Util::FALSE,
        'psgi.multiprocess'      => Plack::Util::TRUE,
        'psgi.run_once'          => Plack::Util::FALSE,
        'psgi.streaming'         => Plack::Util::TRUE,
        'psgi.nonblocking'       => Plack::Util::FALSE,
        'psgix.harakiri'         => Plack::Util::TRUE,
        'psgix.cleanup'          => Plack::Util::TRUE,
        'psgix.cleanup.handlers' => [],
    };

    if (defined(my $HTTP_AUTHORIZATION = $r->headers_in->{Authorization})) {
        $env->{HTTP_AUTHORIZATION} = $HTTP_AUTHORIZATION;
    }

    # If you supply more than one Content-Length header Apache will
    # happily concat the values with ", ", e.g. "72, 72". This
    # violates the PSGI spec so fix this up and just take the first
    # one.
    if (exists $env->{CONTENT_LENGTH} && $env->{CONTENT_LENGTH} =~ /,/) {
        no warnings qw(numeric);
        $env->{CONTENT_LENGTH} = int $env->{CONTENT_LENGTH};
    }

    # Actually, we can not trust PATH_INFO from mod_perl because mod_perl squeezes multiple slashes into one slash.
    my $uri = URI->new("http://".$r->hostname.$r->unparsed_uri);

    $env->{PATH_INFO} = uri_unescape($uri->path);

    $class->fixup_path($r, $env);

    my $res = $app->($env);

    if (ref $res eq 'ARRAY') {
        _handle_response($r, $res);
    }
    elsif (ref $res eq 'CODE') {
        $res->(sub {
            _handle_response($r, $_[0]);
        });
    }
    else {
        die "Bad response $res";
    }

    if (@{ $env->{'psgix.cleanup.handlers'} }) {
        $r->push_handlers(
            PerlCleanupHandler => sub {
                for my $cleanup_handler (@{ $env->{'psgix.cleanup.handlers'} }) {
                    $cleanup_handler->($env);
                }

                if ($env->{'psgix.harakiri.commit'}) {
                    $r->child_terminate;
                }
            },
        );
    } else {
        if ($env->{'psgix.harakiri.commit'}) {
            $r->child_terminate;
        }
    }

    return Apache2::Const::OK;
}

sub handler {
    my $class = __PACKAGE__;
    my $r     = shift;
    my $psgi  = $r->dir_config('psgi_app');
    $class->call_app($r, $class->load_app($psgi));
}

# The method for PH::Apache2::Registry to override.
sub fixup_path {
    my ($class, $r, $env) = @_;

    # $env->{PATH_INFO} is created from unparsed_uri so it is raw.
    my $path_info = $env->{PATH_INFO} || '';

    # Get argument of <Location> or <LocationMatch> directive
    # This may be string or regexp and we can't know either.
    my $location = $r->location;

    # Let's *guess* if we're in a LocationMatch directive
    if ($location eq '/') {
        # <Location /> could be handled as a 'root' case where we make
        # everything PATH_INFO and empty SCRIPT_NAME as in the PSGI spec
        $env->{SCRIPT_NAME} = '';
    } elsif ($path_info =~ s{^($location)/?}{/}) {
        $env->{SCRIPT_NAME} = $1 || '';
    } else {
        # Apache's <Location> is matched but here is not.
        # This is something wrong. We can only respect original.
        $r->server->log_error(
            "Your request path is '$path_info' and it doesn't match your Location(Match) '$location'. " .
            "This should be due to the configuration error. See perldoc Plack::Handler::Apache2 for details."
        );
    }

    $env->{PATH_INFO}   = $path_info;
}

sub _handle_response {
    my ($r, $res) = @_;

    my ($status, $headers, $body) = @{ $res };

    my $hdrs = ($status >= 200 && $status < 300)
        ? $r->headers_out : $r->err_headers_out;

    Plack::Util::header_iter($headers, sub {
        my($h, $v) = @_;
        if (lc $h eq 'content-type') {
            $r->content_type($v);
        } elsif (lc $h eq 'content-length') {
            $r->set_content_length($v);
        } else {
            $hdrs->add($h => $v);
        }
    });

    $r->status($status);

    if (Scalar::Util::blessed($body) and $body->can('path') and my $path = $body->path) {
        $r->sendfile($path);
    } elsif (defined $body) {
        Plack::Util::foreach($body, sub { $r->print(@_) });
        $r->rflush;
    }
    else {
        return Plack::Util::inline_object
            write => sub { $r->print(@_); $r->rflush },
            close => sub { $r->rflush };
    }

    return Apache2::Const::OK;
}

1;

__END__

=encoding utf-8

=head1 NAME

Plack::Handler::Apache2 - Apache 2.0 mod_perl handler to run PSGI application

=head1 SYNOPSIS

  # in your httpd.conf
  <Location />
  SetHandler perl-script
  PerlResponseHandler Plack::Handler::Apache2
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

  # Optionally preload your apps in startup
  PerlPostConfigRequire /etc/httpd/startup.pl

See L</STARTUP FILE> for more details on writing a C<startup.pl>.

=head1 DESCRIPTION

This is a mod_perl handler module to run any PSGI application with mod_perl on Apache 2.x.

If you want to run PSGI applications I<behind> Apache instead of using
mod_perl, see L<Plack::Handler::FCGI> to run with FastCGI, or use
standalone HTTP servers such as L<Starman> or L<Starlet> proxied with
mod_proxy.

=head1 CREATING CUSTOM HANDLER

If you want to create a custom handler that loads or creates PSGI
applications using other means than loading from C<.psgi> files, you
can create your own handler class and use C<call_app> class method to
run your application.

  package My::ModPerl::Handler;
  use Plack::Handler::Apache2;

  sub get_app {
    # magic!
  }

  sub handler {
    my $r = shift;
    my $app = get_app();
    Plack::Handler::Apache2->call_app($r, $app);
  }

=head1 STARTUP FILE

Here is an example C<startup.pl> to preload PSGI applications:

    #!/usr/bin/env perl

    use strict;
    use warnings;
    use Apache2::ServerUtil ();

    BEGIN {
        return unless Apache2::ServerUtil::restart_count() > 1;

        require lib;
        lib->import('/path/to/my/perl/libs');

        require Plack::Handler::Apache2;

        my @psgis = ('/path/to/app1.psgi', '/path/to/app2.psgi');
        foreach my $psgi (@psgis) {
            Plack::Handler::Apache2->preload($psgi);
        }
    }

    1; # file must return true!

See L<http://perl.apache.org/docs/2.0/user/handlers/server.html#Startup_File>
for general information on the C<startup.pl> file for preloading perl modules
and your apps.

Some things to keep in mind when writing this file:

=over 4

=item * multiple init phases

You have to check that L<Apache2::ServerUtil/restart_count> is C<< > 1 >>,
otherwise your app will load twice and the env vars you set with
L<PerlSetEnv|http://perl.apache.org/docs/2.0/user/config/config.html#C_PerlSetEnv_>
will not be available when your app is loading the first time.

Use the example above as a template.

=item * C<@INC>

The C<startup.pl> file is a good place to add entries to your C<@INC>.
Use L<lib> to add entries, they can be in your app or C<.psgi> as well, but if
your modules are in a L<local::lib> or some such, you will need to add the path
for anything to load.

Alternately, if you follow the example above, you can use:

    PerlSetEnv PERL5LIB /some/path

or

    PerlSwitches -I/some/path

in your C<httpd.conf>, which will also work.

=item * loading errors

Any exceptions thrown in your C<startup.pl> will stop Apache from starting at
all.

You probably don't want a stray syntax error to bring your whole server down in
a shared or development environment, in which case it's a good idea to wrap the
L</preload> call in an eval, using something like this:

    require Plack::Handler::Apache2;

    my @psgis = ('/path/to/app1.psgi', '/path/to/app2.psgi');

    foreach my $psgi (@psgis) {
        eval {
            Plack::Handler::Apache2->preload($psgi); 1;
        } or do {
            my $error = $@ || 'Unknown Error';
            # STDERR goes to the error_log
            print STDERR "Failed to load psgi '$psgi': $error\n";
        };
    }


=item * dynamically loaded modules

Some modules load their dependencies at runtime via e.g. L<Class::Load>. These
modules will not get preloaded into your parent process by just including the
app/module you are using.

As an optimization, you can dump C<%INC> from a request to see if you are using
any such modules and preload them in your C<startup.pl>.

Another method is dumping the difference between the C<%INC> on
process start and process exit. You can use something like this to
accomplish this:

    my $start_inc = { %INC };

    END {
        my @m;
        foreach my $m (keys %INC) {
            push @m, $m unless exists $start_inc->{$m};
        }

        if (@m) {
            # STDERR goes to the error_log
            print STDERR "The following modules need to be preloaded:\n";
            print STDERR "$_\n" for @m;
        }
    }

=back

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 CONTRIBUTORS

Paul Driver

Ævar Arnfjörð Bjarmason

Rafael Kitover

=head1 SEE ALSO

L<Plack>

=cut
