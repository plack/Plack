package Plack::Middleware::StackTrace;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use Plack;
use CGI::ExceptionManager;
use CGI::ExceptionManager::StackTrace;
use Encode;

__PACKAGE__->mk_accessors(qw/renderer/);

sub call {
    my($self, $env) = @_;

    my $err_res;
    no warnings 'redefine';
    local *CGI::ExceptionManager::StackTrace::output = sub {
        my ($err, %args) = @_;
        my $body = $err->as_html(%args);
        $err_res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ encode_utf8($body) ]];
    };

    my %args = ();
    my $res = CGI::ExceptionManager->run(
        callback => sub {
            $self->app->($env);
        },
        powered_by => "Plack/$Plack::VERSION",
        renderer => $self->renderer,
    );

    return $err_res || $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::StackTrace - Displays stack trace when your app dies

=head1 SYNOPSIS

  add "Plack::Middleware::StackTrace";

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen.

This middleware is enabled by default when you run L<plackup> in the
default development mode.

=head1 CONFIGURATION

No configuration option is available.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<CGI::ExceptionManager> L<Plack::Middleware>

=cut

