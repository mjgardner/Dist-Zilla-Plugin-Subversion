package Dist::Zilla::Plugin::Subversion;

use strict;
use Modern::Perl;
use utf8;

# VERSION
use Dist::Zilla 4.101550;
1;

# ABSTRACT: update your Subversion repository after release

=head1 DESCRIPTION

This set of plugins for L<Dist::Zilla|Dist::Zilla> can do interesting things for
module authors using Subversion (L<http://subversion.apache.org/>) to track
their work. The following plugins are provided in this distribution:

=over

=item * L<Dist::Zilla::Plugin::Subversion::ReleaseDist|Dist::Zilla::Plugin::Subversion::ReleaseDist>

=item * L<Dist::Zilla::Plugin::Subversion::Tag|Dist::Zilla::Plugin::Subversion::Tag>

=back
