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
enviroments
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
