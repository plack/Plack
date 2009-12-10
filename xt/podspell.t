use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]+/ } <DATA>);
$ENV{LANG} = 'C';
set_spell_cmd("aspell -l en list") if `which aspell`;
all_pod_files_spelling_ok('lib');

__DATA__
AIO
API
AnyEvent
CGI
CPAN
Cascadable
Coro
DSL
FCGI
FastCGI
HTTP
HUP
IP
IRC
Kazuhiro Osawa
Kazuho Oku
Kogman
Middlewares
MockHTTP
Mojo
Mojo's
Namespaces
OO
Oku's
PSGI
Perlbal
Plack
ReverseHTTP
ServerSimple
Tatsuhiko Miyagawa
Tokuhiro Matsuno
URI
URLMap
XS
Yuval
app
backend
callback
cgi
coroutine
env
fallback
filename
github
hookout
hostname
hostnames
http
https
implementors
internet
middleware
middlewares
multithread
namespace
namespaces
natively
nopaste
param
plackup
pm
prefork
psgi
rackup
referer
reversehttp
standalone
stringifies
uri
var
