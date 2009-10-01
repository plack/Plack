use strict;
use Test::More (tests => 2);

BEGIN
{
    use_ok "Plack::Request";
}

can_ok( "Plack::Request",
    qw(address cookies method protocol query_parameters uri user raw_body headers),
    qw(body_params input params query_params path_info body),
    qw(body_parameters cookies hostname param parameters path upload uploads),
    qw(uri_with as_http_request),

    # delegated methods
    qw(content_encoding content_length content_type header referer user_agent)
);
