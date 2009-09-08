#!/usr/bin/perl
# Fork.pm 
# Copyright (c) 2006 Jonathan Rockway <jrockway@cpan.org>

package TestApp::Controller::Fork;

use strict;
use warnings;
use base 'Catalyst::Controller';

eval 'use YAML';

sub system : Local {
    my ($self, $c, $ls) = @_;
    my ($result, $code) = (undef, 1);

    if(!-e $ls || !-x _){ 
        $result = 'skip';
    }
    else {
        $result = system($ls, $ls, $ls);
        $result = $! if $result != 0;
    }
    
    $c->response->body(Dump({result => $result}));
}

sub backticks : Local {
    my ($self, $c, $ls) = @_;
    my ($result, $code) = (undef, 1);
    
    if(!-e $ls || !-x _){ 
        $result = 'skip';
        $code = 0;
    }
    else {
        $result = `$ls $ls $ls` || $!;
        $code = $?;
    }
    
    $c->response->body(Dump({result => $result, code => $code}));
}

sub fork : Local {
    my ($self, $c) = @_;
    my $pid;
    my $x = 0;
    
    if($pid = fork()){
        $x = "ok";
    }
    else {
        exit(0);
    }

    waitpid $pid,0 or die;
    
    $c->response->body(Dump({pid => $pid, result => $x}));
}

1;
