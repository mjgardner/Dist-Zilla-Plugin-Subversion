package Dist::Zilla::Plugin::Subversion::ReleaseDist;

use Modern::Perl;
use utf8;

our $VERSION = '1.101591';    # VERSION
use Moose;
with 'Dist::Zilla::Role::Subversion';
with 'Dist::Zilla::Role::Releaser' => { -version => 4.101550 };

use English qw(-no_match_vars);
use Modern::Perl;
use MooseX::Types::URI 'Uri';
use namespace::autoclean;

has 'dist_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_dist_url {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $url = $ARG[0]->_base_url->clone();
    $url->path_segments( $url->path_segments(), 'dists' );
    return $url;
}

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

# ABSTRACT: releases a distribution's tarball to Subversion

__END__

=pod

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders

=encoding utf8

=head1 NAME

Dist::Zilla::Plugin::Subversion::ReleaseDist - releases a distribution's tarball to Subversion

=head1 VERSION

version 1.101591

=head1 DESCRIPTION

This L<Dist::Zilla|Dist::Zilla> release plugin can be used to copy your
distribution's tarball to a directory in Subversion.
In addition to the attributes listed here, it can be configured with
attributes from
L<Dist::Zilla::Role::Subversion|Dist::Zilla::Role::Subversion>.

=head1 ATTRIBUTES

=head2 dist_url

URL for the directory receiving distribution tarballs.  Defaults to "dists"
within the base directory of the distribution, alongside "trunk", "branches"
and "tags".

=head1 METHODS

=head2 release

Implemented for
L<Dist::Zilla::Role::Releaser|Dist::Zilla::Role::Releaser> role.
Imports the distribution tarball to the Subversion repository.

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

The AnnoCPAN is a website that allows community annonations of Perl module documentation.

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

The CPAN Testers Matrix is a website that provides a visual way to determine what Perls/platforms PASSed for a distribution.

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

This software is copyright (c) 2011 by Mark Gardner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
