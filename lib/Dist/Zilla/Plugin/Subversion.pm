package Dist::Zilla::Plugin::Subversion;

# ABSTRACT: update your Subversion repository after release

use Dist::Zilla;
1;

__END__

=head1 DESCRIPTION

This set of plugins for L<Dist::Zilla> can do interesting things for
module authors using L<Subversion|http://subversion.apache.org/> to track
their work. The following plugins are provided in this distribution:

=over

=item * L<Dist::Zilla::Plugin::Subversion::Tag>

=item * L<Dist::Zilla::Plugin::Subversion::ReleaseDist>

=back
