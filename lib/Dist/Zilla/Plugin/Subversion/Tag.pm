package Dist::Zilla::Plugin::Subversion::Tag;

# ABSTRACT: tags a distribution in Subversion

use Moose;
with 'Dist::Zilla::Role::Subversion';
with 'Dist::Zilla::Role::AfterRelease' => { -version => 4.101550 };

use Cwd;
use English qw(-no_match_vars);
use Modern::Perl;
use MooseX::Types::URI 'Uri';
use namespace::autoclean;

=encoding utf8

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

sub _build_tag_url {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $url = $ARG[0]->_base_url();
    $url->path_segments( $url->path_segments(), 'tags' );
    return $url;
}

=method after_release

Implemented for
L<Dist::Zilla::Role::AfterRelease> role.
Copies the working copy to a tag named after the distribution and its version.

=cut

sub after_release {
    my $self = shift;
    my ( $working_url, $tag_url )
        = map { $self->$ARG } qw(working_url tag_url);
    my %meta = %{ $self->zilla->distmeta() };

    $tag_url->path_segments( $tag_url->path_segments(),
        join q{-}, @meta{qw(name version)} );
    $self->log("Tagging $working_url as $tag_url");

    if ( my $commit_info = $self->_svn->commit( getcwd(), 0 ) ) {
        $self->_log_commit_info( $commit_info,
            "committed working copy to $working_url" );
        if ( $commit_info
            = $self->_svn->copy( "$working_url", 'HEAD', "$tag_url" ) )
        {
            $self->_log_commit_info( $commit_info,
                "tagged $working_url as $tag_url" );
            return;
        }
    }

    $self->log_fatal("Failed tag of $working_url as $tag_url");
    return;
}

__PACKAGE__->meta->make_immutable();
no Moose;
1;

__END__

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> after-release plugin can be used to tag your
distribution in Subversion.
In addition to the attributes listed here, it can be configured with
attributes from
L<Dist::Zilla::Role::Subversion|Dist::Zilla::Role::Subversion>.
