use Plack::MIME;
use Test::More;

Plack::MIME->add_type(".foo" => "text/foo");
is( Plack::MIME->mime_type("bar.foo"), "text/foo" );

Plack::MIME->add_type(".c" => "application/c-source");
is( Plack::MIME->mime_type("FOO.C"), "application/c-source" );

Plack::MIME->add_type(".ng-html" => "text/ng-template");
is( Plack::MIME->mime_type("foo.ng-html"), "text/ng-template" );

done_testing;
