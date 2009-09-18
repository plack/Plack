package Plack::Middleware::DebugScreen;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use CGI::ExceptionManager;
use CGI::ExceptionManager::StackTrace;
use Encode;

__PACKAGE__->mk_accessors(qw/powered_by renderer/);

sub app_handler {
    my $self = shift;

    return sub {
        my $env = shift;

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
    };
}

1;
