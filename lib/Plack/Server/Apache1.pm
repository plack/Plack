package Plack::Server::Apache1;
use strict;
use Apache::Request;
use Apache::Constants qw(:common :response);

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
    my $apr = Apache::Request->new($r);

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

    return OK;
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
        } else {
            $hdrs->add($h => $v);
        }
    });

    $r->status($status);
    $r->send_http_header;

    if (defined $body) {
        if (Plack::Util::is_real_fh($body)) {
            $r->send_fd($body);
        } else {
            Plack::Util::foreach($body, sub { $r->print(@_) });
        }
    }
    else {
        return Plack::Util::inline_object
            write => sub { $r->print(@_) },
            close => sub { };
    }
}

1;

__END__


=head1 NAME

Plack::Server::Apache1 - Apache 1.3.x handlers to run PSGI application

=head1 SYNOPSIS

  <Locaion />
  SetHandler perl-script
  PerlHandler Plack::Server::Apache1
  PerlSetVar psgi_app /path/to/app.psgi
  </Location>

  <Perl>
  use Plack::Server::Apache1;
  Plack::Server::Apache1->preload("/path/to/app.psgi");
  </Perl>

=head1 AUTHOR

Aaron Trevena

Tatsuhiko Miyagawa

=cut

