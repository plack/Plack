use Test::More;
eval q{ use Test::Spelling };
plan skip_all => "Test::Spelling is not installed." if $@;
add_stopwords(map { split /[\s\:\-]+/ } <DATA>);
$ENV{LANG} = 'C';
set_spell_cmd("aspell -l en list") if `which aspell`;
all_pod_files_spelling_ok('lib');

__DATA__
Plack
Kazuhiro Osawa
Tokuhiro Matsuno
Tatsuhiko Miyagawa
API
CGI
FCGI
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
Coro
FastCGI
rackup
Impl
Mojo
prefork
callback
ReverseHTTP
hookout
internet
AIO
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
Kazuho Oku
XS
DSL
coroutine
psgi
namespace
filename
OO
natively
reversehttp
Mojo's
stringifies
plackup
implementors
Oku's
