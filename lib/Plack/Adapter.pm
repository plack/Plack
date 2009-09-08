package Plack::Adapter;
use strict;
use Carp ();
use Plack::Util;

sub adapter_for {
    my($class, $app, $adapter) = @_;

    if (!$adapter && $app =~ /\.cgi$/) {
        require Plack::Adapter::CGI;
        return Plack::Adapter::CGI->new(sub { do $app });
    } else {
        Plack::Util::load_class($app);
        $adapter ||= $app->plack_adapter if $app->can('plack_adapter');
        Carp::croak("Can't get adapter for app $app: Specify with -a or plack_adapter() method") unless $adapter;
        Plack::Util::load_class($adapter, "Plack::Adapter")->new($app);
    }
}

1;
