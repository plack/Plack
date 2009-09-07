package TestApp::Controller::Priorities;

use strict;
use base 'Catalyst::Controller';

#
#   Regex vs. Local
#

sub re_vs_loc_re :Regex('/priorities/re_vs_loc') { $_[1]->res->body( 'regex' ) }
sub re_vs_loc    :Local                          { $_[1]->res->body( 'local' ) }

#
#   Regex vs. LocalRegex
#

sub re_vs_locre_locre :LocalRegex('re_vs_(locre)')      { $_[1]->res->body( 'local_regex' ) }
sub re_vs_locre_re    :Regex('/priorities/re_vs_locre') { $_[1]->res->body( 'regex' ) }

#
#   Regex vs. Path
#

sub re_vs_path_path :Path('/priorities/re_vs_path')  { $_[1]->res->body( 'path' ) }
sub re_vs_path_re   :Regex('/priorities/re_vs_path') { $_[1]->res->body( 'regex' ) }

#
#   Local vs. LocalRegex
#

sub loc_vs_locre_locre :LocalRegex('loc_vs_locre') { $_[1]->res->body( 'local_regex' ) }
sub loc_vs_locre       :Local                      { $_[1]->res->body( 'local' ) }

#
#   Local vs. Path (depends on definition order)
#

sub loc_vs_path1_loc :Path('/priorities/loc_vs_path1') { $_[1]->res->body( 'path' ) }
sub loc_vs_path1     :Local                            { $_[1]->res->body( 'local' ) }

sub loc_vs_path2     :Local                            { $_[1]->res->body( 'local' ) }
sub loc_vs_path2_loc :Path('/priorities/loc_vs_path2') { $_[1]->res->body( 'path' ) }

#
#   Path vs. LocalRegex
#

sub path_vs_locre_locre :LocalRegex('path_vs_(locre)')     { $_[1]->res->body( 'local_regex' ) }
sub path_vs_locre_path  :Path('/priorities/path_vs_locre') { $_[1]->res->body( 'path' ) }

#
#   Regex vs. index (has sub controller)
#

sub re_vs_idx :Regex('/priorities/re_vs_index') { $_[1]->res->body( 'regex' ) }

#
#   Local vs. index (has sub controller)
#

sub loc_vs_index :Local { $_[1]->res->body( 'local' ) }

#
#   LocalRegex vs. index (has sub controller)
#

sub locre_vs_idx :LocalRegex('locre_vs_index') { $_[1]->res->body( 'local_regex' ) }

#
#   Path vs. index (has sub controller)
#

sub path_vs_idx :Path('/priorities/path_vs_index') { $_[1]->res->body( 'path' ) }

1;
