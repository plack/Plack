use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]/ } <DATA>);
$ENV{LANG} = 'C';
all_pod_files_spelling_ok('lib');
__DATA__
Kazuhiro Osawa
yappo <at> shibuya <döt> pl
Plack
Matsuno
Tokuhiro
slkjfd
Tatsuhiko
Miyagawa
dankogai
kogaidan
API
CGI
Stringifies
URI
https
param
pm
referer
uri
HTTP
hostname
IP
PSGI
ServerSimple
app
Mojo
AnyEvent
Coro's
Lehmann
myhttpd
FastCGI
rackup
Impl
Mojo's
prefork
callback
ReverseHTTP
hookout
internet
ReverseHTTP
reversehttp
AIO
Coro
multithread
var
env
middleware
HUP
standalone
fallback
MockHTTP
backend
CPAN
Perlbal
Kazuho
Oku's
XS
DSL
psgi
