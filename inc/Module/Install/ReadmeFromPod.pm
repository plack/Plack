#line 1
package Module::Install::ReadmeFromPod;

use 5.006;
use strict;
use warnings;
use base qw(Module::Install::Base);
use vars qw($VERSION);

$VERSION = '0.12';

sub readme_from {
  my $self = shift;
  return unless $self->is_admin;

  my $file = shift || $self->_all_from
    or die "Can't determine file to make readme_from";
  my $clean = shift;

  print "Writing README from $file\n";

  require Pod::Text;
  my $parser = Pod::Text->new();
  open README, '> README' or die "$!\n";
  $parser->output_fh( *README );
  $parser->parse_file( $file );
  if ($clean) {
    $self->clean_files('README');
  }
  return 1;
}

sub _all_from {
  my $self = shift;
  return unless $self->admin->{extensions};
  my ($metadata) = grep {
    ref($_) eq 'Module::Install::Metadata';
  } @{$self->admin->{extensions}};
  return unless $metadata;
  return $metadata->{values}{all_from} || '';
}

'Readme!';

__END__

#line 112

