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
        local $ENV{MOD_PERL}; # trick Catalyst/CGI.pm etc.
        Plack::Util::load_psgi $app;
    };
}

sub call_app {
    my ($class, $r, $app) = @_;

    $r->subprocess_env; # let Apache create %ENV for us :)

    my $env = {
        %ENV,
        'psgi.version'        => [ 1, 1 ],
        'psgi.url_scheme'     => ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'          => $r,
        'psgi.errors'         => *STDERR,
        'psgi.multithread'    => Plack::Util::FALSE,
        'psgi.multiprocess'   => Plack::Util::TRUE,
        'psgi.run_once'       => Plack::Util::FALSE,
        'psgi.streaming'      => Plack::Util::TRUE,
        'psgi.nonblocking'    => Plack::Util::FALSE,
        'psgix.harakiri'      => Plack::Util::TRUE,
    };

    if (defined(my $HTTP_AUTHORIZATION = $r->headers_in->{Authorization})) {
        $env->{HTTP_AUTHORIZATION} = $HTTP_AUTHORIZATION;
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

    if ($env->{'psgix.harakiri.commit'}) {
        $r->child_terminate;
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

=head1 NAME

Plack::Handler::Apache2 - Apache 2.0 handlers to run PSGI application

=head1 SYNOPSIS

  <Location />
  SetHandler perl-script
  PerlResponseHandler Plack::Handler::Apache2
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

  # Optional, preload the application in the parent like startup.pl
  <Perl>
  use Plack::Handler::Apache2;
  Plack::Handler::Apache2->preload("/path/to/app.psgi");
  </Perl>

=head1 DESCRIPTION

This is a handler module to run any PSGI application with mod_perl on Apache 2.x.

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

=head1 AUTHOR

Tatsuhiko Miyagawa

=head1 CONTRIBUTORS

Paul Driver

=head1 SEE ALSO

L<Plack>

=cut
