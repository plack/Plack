#!/usr/bin/perl
use CGI;
my $q = CGI->new;
print $q->header, "Hello ", scalar $q->param('name'), " counter=", ++$COUNTER;
