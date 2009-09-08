package Plack::Adapter;
use strict;
use Plack::Util;

sub adapter_for {
    my($class, $app) = @_;
    if ($app =~ /\.cgi$/) {
        require Plack::Adapter::CGI;
        return Plack::Adapter::CGI->new(sub { do $app });
    } else {
        Plack::Util::load_class($app);
        if ($app->isa('Catalyst')) {
            require Plack::Adapter::Catalyst;
            Plack::Adapter::Catalyst->new($app);
        } elsif ($app->isa('CGI::Application')) {
            require Plack::Adapter::CGIApplication;
            Plack::Adapter::CGIApplication->new(sub { $app->new->run });
        } elsif ($app->isa('Plack::Adapter::Callable')) {
            require Plack::Adapter::Callable;
            Plack::Adapter::Callable->new($app);
        }
    }
}

1;
