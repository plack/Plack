package Plack::Server::Apache1;
use strict;

=head1 NAME

Plack::Server::Apache1 - Apache 1.3.x handlers to run PSGI application

=head1 SYNOPSIS

  <Locaion />
  SetHandler perl-script
  PerlHandler Plack::Server::Apache1
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

=cut

use Apache::Request;
use Apache::Constants qw(:common :response);

use Plack::Util;
use Scalar::Util;

=head2 handler

Apache mod_perl handler, takes apache request object, returns Apache constant for HTTP Status

=cut

my %apps; # psgi file to $app mapping

sub handler {
    my $r = shift;
    my $apr = Apache::Request->new($r);

    my $psgi = $r->dir_config('psgi_app');

    my $app = $apps{$psgi} ||= do {
        delete $ENV{MOD_PERL}; # trick Catalyst/CGI.pm etc.
        Plack::Util::load_psgi $psgi;
    };

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
    };

    my $vpath    = $env->{SCRIPT_NAME} . $env->{PATH_INFO};

    my $location = $r->location || "/";
       $location =~ s!/$!!;
    (my $path_info = $vpath) =~ s/^\Q$location\E//;

    $env->{SCRIPT_NAME} = $location;
    $env->{PATH_INFO}   = $path_info;

    my($status, $headers, $body) = @{ $app->($env) };

    my $hdrs = ($status >= 200 && $status < 300)
        ? $r->headers_out : $r->err_headers_out;

    Plack::Util::header_iter($headers, sub {
        my($h, $v) = @_;
        if (lc $h eq 'content-type') {
            $r->content_type($v);
        } else {
            $hdrs->add($h => $v);
        }
    });

    $r->status($status);
    $r->send_http_header;

    if(Plack::Util::is_real_fh($body)) {
	$r->send_fd($body);
    } else {
        Plack::Util::foreach($body, sub { $r->print(@_) });
    }


    return OK;
}

1;

__END__

=head1 AUTHOR

Aaron Trevena

=cut

