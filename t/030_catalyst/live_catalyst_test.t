use FindBin;
use lib "$FindBin::Bin/lib";
use Catalyst::Test 'TestApp', {default_host => 'default.com'};
use Catalyst::Request;

use Test::More tests => 8;

content_like('/',qr/root/,'content check');
action_ok('/','Action ok ok','normal action ok');
action_redirect('/engine/response/redirect/one','redirect check');
action_notfound('/engine/response/status/s404','notfound check');
contenttype_is('/action/local/one','text/plain','Contenttype check');

my $creq;
my $req = '/dump/request';

{
    eval '$creq = ' . request($req)->content;
    is( $creq->uri->host, 'default.com', 'request targets default host set via import' );
}

{
    local $Catalyst::Test::default_host = 'localized.com';
    eval '$creq = ' . request($req)->content;
    is( $creq->uri->host, 'localized.com', 'target host is mutable via package var' );
}

{
    my %opts = ( host => 'opthash.com' );
    eval '$creq = ' . request($req, \%opts)->content;
    is( $creq->uri->host, $opts{host}, 'target host is mutable via options hashref' );
}
