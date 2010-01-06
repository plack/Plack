package Plack::Server::Apache2;
use strict;
use warnings;
use Apache2::RequestRec;
use Apache2::RequestIO;
use Apache2::RequestUtil;
use Apache2::Response;
use Apache2::Const -compile => qw(OK);
use APR::Table;
use IO::Handle;
use Plack::Util;
use Scalar::Util;

my %apps; # psgi file to $app mapping

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

sub handler {
    my $r = shift;

    my $psgi = $r->dir_config('psgi_app');
    my $app = __PACKAGE__->load_app($psgi);

    $r->subprocess_env; # let Apache create %ENV for us :)

    my $env = {
        %ENV,
        'psgi.version'        => [ 1, 0 ],
        'psgi.url_scheme'     => ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'          => $r,
        'psgi.errors'         => *STDERR,
        'psgi.multithread'    => Plack::Util::FALSE,
        'psgi.multiprocess'   => Plack::Util::TRUE,
        'psgi.run_once'       => Plack::Util::FALSE,
        'psgi.streaming'      => Plack::Util::TRUE,
    };

    my $vpath    = $env->{SCRIPT_NAME} . $env->{PATH_INFO};
    my $location = $r->location || "/";
       $location =~ s{/$}{};
    (my $path_info = $vpath) =~ s/^\Q$location\E//;

    $env->{SCRIPT_NAME} = $location;
    $env->{PATH_INFO}   = $path_info;

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

    return Apache2::Const::OK;
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

Plack::Server::Apache2 - Apache 2.0 handlers to run PSGI application

=head1 SYNOPSIS

  <Locaion />
  SetHandler perl-script
  PerlResponseHandler Plack::Server::Apache2
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

  <Perl>
  use Plack::Server::Apache2;
  Plack::Server::Apache2->preload("/path/to/app.psgi");
  </Perl>

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
