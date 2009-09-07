package Plack::Middleware::DebugScreen;
use strict;
use warnings;
use CGI::ExceptionManager;
use CGI::ExceptionManager::StackTrace;

use overload '&{}' => sub {
    my $self = $_[0];
    sub {
        my $err_res;
        no warnings 'redefine';
        local *CGI::ExceptionManager::StackTrace::output = sub {
            my ($err, %args) = @_;
            my $body = $err->as_html(%args);
            utf8::encode($body);
            $err_res = [500, ['Content-Type' => 'text/html; charset=utf-8'], $body];
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
  },
  fallback => 1;
use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(qw/code powered_by renderer/);

sub new {
    my $class = shift;
    bless(@_ == 1 ? $_[0] : +{@_}, $class);
}

1;
