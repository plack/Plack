#!perl

use CGI;
binmode STDOUT, ":utf8";
print CGI::header("text/html;charset=utf-8"), chr(4343), "\n";

