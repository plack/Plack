#!/usr/bin/perl
use Data::Dumper;
print "Content-Type: text/plain\r\n\r\n";
print 'my ' . Dumper \%ENV;
