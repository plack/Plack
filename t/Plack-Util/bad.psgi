use strict;

eval { load_class("CGI") };
sub { [ 200, [], ["Hello"] ] };

