use Plack::Builder;
use File::Basename qw(dirname);

my $handler = sub {
    return [ 404, [ "Content-Type" => "text/plain" ], [ "Not Found" ] ];
};

builder {
    enable "Plack::Middleware::ConditionalGET";
    enable "Plack::Middleware::Static",
        path => qr/./, root => dirname(__FILE__) . '/static';
    $handler;
};
