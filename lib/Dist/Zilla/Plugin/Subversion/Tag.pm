package Dist::Zilla::Plugin::Subversion::Tag;

use strict;
use Modern::Perl;
use utf8;

our $VERSION = '1.101591';    # VERSION

use Cwd;
use English qw(-no_match_vars);
use Moose;
use MooseX::Types::URI 'Uri';
use namespace::autoclean;
with 'Dist::Zilla::Role::Subversion';
with 'Dist::Zilla::Role::AfterRelease' => { -version => 4.101550 };

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

sub after_release {
    my $self = shift;
    my ( $working_url, $tag_url )
        = map { $self->$ARG } qw(working_url tag_url);
    my %meta = %{ $self->zilla->distmeta() };

    my @segments = $tag_url->path_segments();
    $tag_url->path_segments( @segments, join q{-}, @meta{qw(name version)} );
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

# ABSTRACT: tags a distribution in Subversion

__END__

=pod

=encoding utf8

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders metacpan

=head1 NAME

Dist::Zilla::Plugin::Subversion::Tag - tags a distribution in Subversion

=head1 VERSION

version 1.101591

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> after-release plugin can be used to tag your
distribution in Subversion.
In addition to the attributes listed here, it can be configured with
attributes from
L<Dist::Zilla::Role::Subversion|Dist::Zilla::Role::Subversion>.

=head1 ATTRIBUTES

=head2 tag_url

URL for the directory receiving tags for your distribution.  During release
this will be appended with a directory named with your distribution's name
and version number.

=head1 METHODS

=head2 after_release

Implemented for
L<Dist::Zilla::Role::AfterRelease|Dist::Zilla::Role::AfterRelease> role.
Copies the working copy to a tag named after the distribution and its version.

=head1 SUPPORT

=head2 Perldoc

You can find documentation for this module with the perldoc command.

  perldoc Dist::Zilla::Plugin::Subversion

=head2 Websites

The following websites have more information about this module, and may be of help to you. As always,
in addition to those websites please use your favorite search engine to discover more resources.

=over 4

=item *

Search CPAN

The default CPAN search engine, useful to view POD in HTML format.

L<http://search.cpan.org/dist/Dist-Zilla-Plugin-Subversion>

=item *

AnnoCPAN

The AnnoCPAN is a website that allows community annotations of Perl module documentation.

L<http://annocpan.org/dist/Dist-Zilla-Plugin-Subversion>

=item *

CPAN Ratings

The CPAN Ratings is a website that allows community ratings and reviews of Perl modules.

L<http://cpanratings.perl.org/d/Dist-Zilla-Plugin-Subversion>

=item *

CPANTS

The CPANTS is a website that analyzes the Kwalitee ( code metrics ) of a distribution.

L<http://cpants.perl.org/dist/overview/Dist-Zilla-Plugin-Subversion>

=item *

CPAN Testers

The CPAN Testers is a network of smokers who run automated tests on uploaded CPAN distributions.

L<http://www.cpantesters.org/distro/D/Dist-Zilla-Plugin-Subversion>

=item *

CPAN Testers Matrix

The CPAN Testers Matrix is a website that provides a visual overview of the test results for a distribution on various Perls/platforms.

L<http://matrix.cpantesters.org/?dist=Dist-Zilla-Plugin-Subversion>

=item *

CPAN Testers Dependencies

The CPAN Testers Dependencies is a website that shows a chart of the test results of all dependencies for a distribution.

L<http://deps.cpantesters.org/?module=Dist::Zilla::Plugin::Subversion>

=back

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the web
interface at L<https://github.com/mjgardner/Dist-Zilla-Plugin-Subversion/issues>. You will be automatically notified of any
progress on the request by the system.

=head2 Source Code

The code is open to the world, and available for you to hack on. Please feel free to browse it and play
with it, or whatever. If you want to contribute patches, please send me a diff or prod me to pull
from your repository :)

L<https://github.com/mjgardner/Dist-Zilla-Plugin-Subversion>

  git clone git://github.com/mjgardner/Dist-Zilla-Plugin-Subversion.git

=head1 AUTHOR

Mark Gardner <mjgardner@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
