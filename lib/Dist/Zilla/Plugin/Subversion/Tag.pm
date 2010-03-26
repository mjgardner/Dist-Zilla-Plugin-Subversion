package Dist::Zilla::Plugin::Subversion::Tag;

# ABSTRACT: tags a distribution in Subversion

# last changed on:
# $Date$
# $Revision$
# $HeadURL$
# $Author$

use Moose;
with 'Dist::Zilla::Role::Subversion';
with 'Dist::Zilla::Role::AfterRelease';

use Cwd;
use English qw(-no_match_vars);
use Moose::Util::TypeConstraints 'find_type_constraint';
use MooseX::Types::URI 'Uri';
use SVN::Client;
use namespace::autoclean;

=attr tag_url

URL for the directory receiving tags for your distribution.  During release
this will be appended with a directory named with your distribution's name
and version number.

=cut

has 'tag_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_tag_url {
    my $url = $ARG[0]->_base_url();
    $url->path_segments( $url->path_segments(), 'tags' );
    return $url;
}

=method after_release

Implemented for
L<Dist::Zilla::Role::AfterRelease|Dist::Zilla::Role::AfterRelease> role.
Copies the working copy to a tag named after the distribution and its version.

=cut

sub after_release {
    my $self = shift;
    my ( $working_url, $tag_url )
        = map { $self->$ARG } qw(working_url tag_url);
    my %meta = %{ $self->zilla->distmeta() };

    $tag_url->path_segments( $tag_url->path_segments(),
        join '-', @meta{qw(name version)} );
    $self->log("Tagging $working_url as $tag_url");

    if ( my $commit_info = $self->_svn->commit( getcwd(), 0 ) ) {
        $self->log( $commit_info->author()
                . " committed working copy on "
                . $commit_info->date() );
        if ( $commit_info
            = $self->_svn->copy( "$working_url", 'HEAD', "$tag_url" ) )
        {
            $self->log( $commit_info->author()
                    . " tagged $working_url as $tag_url on "
                    . $commit_info->date() );
            return;
        }
    }

    $self->log_fatal("Failed tag of $working_url as $tag_url");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> after-release plugin can be used to tag your
distribution in Subversion.
In addition to the attributes listed here, it can be configured with
attributes from
L<Dist::Zilla::Role::Subversion|Dist::Zilla::Role::Subversion>.
