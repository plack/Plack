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
Coro
DSL
FCGI
FastCGI
HTTP
HUP
IP
Kazuhiro Osawa
Kazuho Oku
MockHTTP
Mojo
Mojo's
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
XS
app
backend
callback
coroutine
env
fallback
filename
hookout
hostname
https
implementors
internet
middleware
multithread
namespace
natively
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
