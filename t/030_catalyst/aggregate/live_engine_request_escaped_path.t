#!/usr/bin/evn perl
use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/../lib";

use Test::More tests => 6;
use TestApp;
use HTTP::Request::AsCGI;

=pod

This test exposes a problem in the handling of PATH_INFO in C::Engine::CGI (and
other engines) where Catalyst does not un-escape the request correctly.
If a request is URL-encoded then Catalyst fails to decode the request 
and thus will try and match actions using the URL-encoded value.

Can NOT use Catalyst::Test as it uses HTTP::Request::AsCGI which does
correctly unescape the path (by calling $uri = $uri->canonical).

This will fix the problem for the CGI engine, but is probably the
wrong place.  And also does not fix $uri->base, either.

Plus, the same issue is in Engine::Apache* and other engines.

Index: lib/Catalyst/Engine/CGI.pm
===================================================================
--- lib/Catalyst/Engine/CGI.pm  (revision 7821)
+++ lib/Catalyst/Engine/CGI.pm  (working copy)
@@ -157,6 +157,8 @@
     my $query = $ENV{QUERY_STRING} ? '?' . $ENV{QUERY_STRING} : '';
     my $uri   = $scheme . '://' . $host . '/' . $path . $query;
 
+    $uri = URI->new( $uri )->canonical;
+
     $c->request->uri( bless \$uri, $uri_class );
 
     # set the base URI

=cut

# test that un-escaped can be feteched.
{

    my $request = Catalyst::Utils::request( 'http://localhost/args/params/one/two' );
    my $cgi     = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

    TestApp->handle_request( env => \%ENV );

    ok( my $response = $cgi->restore->response );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content, 'onetwo' );
}

# test that request with URL-escaped code works.
TODO: {
    local $TODO = 'Actions should match when path parts are url encoded';
    my $request = Catalyst::Utils::request( 'http://localhost/args/param%73/one/two' );
    my $cgi     = HTTP::Request::AsCGI->new( $request, %ENV )->setup;

    # Reset PATH_INFO because AsCGI calls $uri = $uri->canonical which
    # will unencode the path and hide the problem from the test.
    $ENV{PATH_INFO} = '/args/param%73/one/two';


    TestApp->handle_request( env => \%ENV );

    ok( my $response = $cgi->restore->response );
    ok( $response->is_success, 'Response Successful 2xx' );
    is( $response->content, 'onetwo' );
}

