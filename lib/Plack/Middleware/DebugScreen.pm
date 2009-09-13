package Plack::Middleware::DebugScreen;
use strict;
use warnings;
use base qw/Plack::Middleware/;
use CGI::ExceptionManager;
use CGI::ExceptionManager::StackTrace;

__PACKAGE__->mk_accessors(qw/powered_by renderer/);

sub call {
    my $self = shift;

    my $err_res;
    no warnings 'redefine';
    local *CGI::ExceptionManager::StackTrace::output = sub {
        my ($err, %args) = @_;
        my $body = $err->as_html(%args);
        utf8::encode($body);
        $err_res = [500, ['Content-Type' => 'text/html; charset=utf-8'], [ $body ]];
    };
    my %args = ();
    my $res = CGI::ExceptionManager->run(
        callback => sub {
            $self->code->(@_);
        },
        powered_by => $self->powered_by || 'Plack',
        renderer => $self->renderer,
    );
    return $err_res || $res;
}

sub new {
    my $class = shift;
    bless(@_ == 1 ? $_[0] : +{@_}, $class);
}

1;
