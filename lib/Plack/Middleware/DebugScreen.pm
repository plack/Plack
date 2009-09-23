package Plack::Middleware::DebugScreen;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use CGI::ExceptionManager;
use CGI::ExceptionManager::StackTrace;
use Encode;

__PACKAGE__->mk_accessors(qw/powered_by renderer/);

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
        powered_by => $self->powered_by || 'Plack',
        renderer => $self->renderer,
    );

    return $err_res || $res;
}

1;

__END__

=head1 NAME

Plack::Middleware::DebugScreen - Displays stack trace when your app dies

=head1 SYNOPSIS

  enable Plack::Middleware::DebugScreen;

=head1 DESCRIPTION

This middleware catches exceptions (run-time errors) happening in your
application and displays nice stack trace screen.

=head1 CONFIGURATION

No configuration option is available.

=head1 AUTHOR

Tokuhiro Matsuno

=head1 SEE ALSO

L<CGI::ExceptionManager> L<Plack::Middleware>

=cut

