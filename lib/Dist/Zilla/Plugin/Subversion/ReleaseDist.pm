package Dist::Zilla::Plugin::Subversion::ReleaseDist;

# ABSTRACT: releases a distribution's tarball to Subversion

# last changed on:
# $Date$
# $Revision$
# $HeadURL$
# $Author$

use Moose;
with 'Dist::Zilla::Role::Subversion';
with 'Dist::Zilla::Role::Releaser';

use English qw(-no_match_vars);
use MooseX::Types::URI 'Uri';
use namespace::autoclean;

=attr dist_url

URL for the directory receiving distribution tarballs.  Defaults to "dists"
within the base directory of the distribution, alongside "trunk", "branches"
and "tags".

=cut

has 'dist_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_dist_url {
    my $url = $ARG[0]->_base_url->clone();
    $url->path_segments( $url->path_segments(), 'dists' );
    return $url;
}

=method release

Implemented for
L<Dist::Zilla::Role::Releaser|Dist::Zilla::Role::Releaser> role.
Imports the distribution tarball to the Subversion repository.

=cut

sub release {
    my ( $self, $archive ) = @ARG;

    my $dist_url = $self->dist_url->clone();
    $dist_url->path_segments( $dist_url->path_segments(),
        $archive->basename() );
    $self->log("Importing $archive to $dist_url");

    if ( my $commit_info = $self->_svn->import( "$archive", "$dist_url", 0 ) )
    {
        $self->_log_commit_info( $commit_info,
            "imported $archive as $dist_url revision" );
        return;
    }

    $self->log_fatal("Failed import of $archive as $dist_url");
    return;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

__END__

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> release plugin can be used to copy your
distribution's tarball to a directory in Subversion.
In addition to the attributes listed here, it can be configured with
attributes from
L<Dist::Zilla::Role::Subversion|Dist::Zilla::Role::Subversion>.
