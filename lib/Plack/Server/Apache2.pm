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

my %apps; # psgi file to $app mapping

sub handler {
    my $r = shift;

    my $psgi = $r->dir_config('psgi_app');

    my $app = $apps{$psgi} ||= do {
        delete $ENV{MOD_PERL}; # trick Catalyst/CGI.pm etc.
        my $app = do $psgi;
        unless (defined $app && ref $app eq 'CODE') {
            die "Can't load psgi_app from $psgi: ", ($@ || $!);
        }
        $app;
    };

    $r->subprocess_env; # let Apache create %ENV for us :)

    my $env = {
        %ENV,
        'psgi.version'        => [ 1, 0 ],
        'psgi.url_scheme'     => ($ENV{HTTPS}||'off') =~ /^(?:on|1)$/i ? 'https' : 'http',
        'psgi.input'          => $r,
        'psgi.errors'         => *STDERR, # xxx
        'psgi.multithread'    => Plack::Util::FALSE,
        'psgi.multiprocess'   => Plack::Util::TRUE,
        'psgi.run_once'       => Plack::Util::FALSE,
    };

    # http://gist.github.com/187070 and PSGI spec
    if ($env->{SCRIPT_NAME} eq '/' and $env->{PATH_INFO} eq '') {
        $env->{SCRIPT_NAME} = '';
        $env->{PATH_INFO}   = '/';
    }

    my $res = $app->($env);

    my $headers = ($res->[0] >= 200 && $res->[0] < 300)
        ? $r->headers_out : $r->err_headers_out;

    while (my($h, $v) = splice(@{$res->[1]}, 0, 2)) {
        if ($h =~ /Content-Type/i) {
            $r->content_type($v);
        } elsif ($h =~ /Content-Length/i) {
            $r->set_content_length($v);
        } else {
            $headers->add($h => $v);
        }
    }

    $r->status($res->[0]);
    # TODO $r->sendfile support?
    Plack::Util::foreach($res->[2], sub { $r->puts(@_) });

    return Apache2::Const::OK;
}

1;

__END__

=head1 NAME

Plack::Server::Apache2 - Apache 2.0 handlers to run PSGI application

=head1 SYNOPSIS

  <Locaion />
  SetHandler perl-script
  PerlHandler Plack::Server::Apache2
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

=head1 AUTHOR

Tatsuhiko Miyagawa

=cut
