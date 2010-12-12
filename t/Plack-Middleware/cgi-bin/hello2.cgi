#!/usr/bin/perl
use CGI;
my $q = CGI->new;
print $q->header, "Hello ", $q->param('name'), " counter=", ++$COUNTER;
