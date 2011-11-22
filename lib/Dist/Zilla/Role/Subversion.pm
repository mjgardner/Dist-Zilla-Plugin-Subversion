package Dist::Zilla::Role::Subversion;

use strict;
use Modern::Perl;
use utf8;

our $VERSION = '1.101591';    # VERSION
use Cwd;
use English qw(-no_match_vars);
use Path::Class qw(dir file);
use Readonly;
use Regexp::DefaultFlags;
use SVN::Client;
use SVN::Wc;
use Moose::Role;
use MooseX::Types::URI 'Uri';
use namespace::autoclean;
with 'Dist::Zilla::Role::Plugin' => { -version => 4.101550 };

for my $attr (qw(svn_user svn_password)) {
    has $attr => (
        is        => 'ro',
        isa       => 'Str',
        predicate => "_has_$attr",
    );
}

has 'working_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_working_url {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
    my $url;
    if ( $url = $self->zilla->distmeta->{resources}{repository} ) {
        return URI->new($url);
    }
    $self->_svn->info( getcwd(), undef, undef,
        sub { $url = URI->new( $ARG[1]->URL() ) }, 0 );
    return $url;
}

has '_base_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build__base_url {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;

    my $url        = $self->working_url->clone();
    my @segments   = $url->path_segments();
    my %url_offset = (
        trunk    => -1,
        branches => -2,
    );
    while ( my ( $segment, $offset ) = each %url_offset ) {
        if ( $segments[$offset] eq $segment ) {
            $url->path_segments( @segments[ 0 .. $#segments + $offset ] );
            return $url;
        }
    }
    $self->_svn->info( getcwd(), undef, undef,
        sub { $url = URI->new( $ARG[1]->repos_root_URL() ) }, 0 );
    return $url;
}

has '_svn' => (
    is         => 'ro',
    isa        => 'SVN::Client',
    lazy_build => 1,
);

sub _build__svn {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my $self = shift;
## no critic (ProhibitCallsToUnexportedSubs)

    my @auth_baton = (
        SVN::Client::get_simple_provider(),
        SVN::Client::get_username_provider(),
    );
    if ( $self->_has_svn_user() and $self->_has_svn_password() ) {
        unshift @auth_baton, SVN::Client::get_simple_prompt_provider(
            sub {
                for my $attr (qw(username password)) {
                    $ARG[0]->$attr( $self->$attr );
                }
            },
            0,
        );
    }

    my $ctx_ref = SVN::Client->new(
        auth    => \@auth_baton,
        log_msg => sub { ${ $ARG[0] } = '[' . caller(1) . ']' },
        notify  => $self->_make_notify_callback(),
    );
    return $ctx_ref;
}

# set up constant hashes of Subversion status codes to names
Readonly my %_ACTION_NAME => _codes_to_hash('SVN::Wc::Notify::Action');
Readonly my %_STATE_NAME  => _codes_to_hash('SVN::Wc::Notify::State');
Readonly my %_NODE_NAME   => _codes_to_hash('SVN::Node');

sub _make_notify_callback {
    my $self = shift;
    return sub {
        my ( $path, $action, $node_kind, undef, $state, $revision_num )
            = @ARG;

        $self->log(
            join q{ },
            '[SVN]',
            grep {$ARG} (
                $_ACTION_NAME{$action},  $_STATE_NAME{$state},
                $_NODE_NAME{$node_kind}, $path,
                "r$revision_num",
            ),
        );
        return;
    };
}

sub _codes_to_hash {
    my $package = (shift) . q{::};
    no strict 'refs';    ## no critic (ProhibitNoStrict)
    return map { ${ ${$package}{$ARG} } => $ARG }
        grep { ${ ${$package}{$ARG} } }
        keys %{$package};
}

sub _log_commit_info {    ## no critic (ProhibitUnusedPrivateSubroutines)
    my ( $self, $commit_info, $message ) = @ARG;

    $self->log(
        join q{ }, $commit_info->author(),
        $message,  $commit_info->revision(),
        'on',      $commit_info->date(),
    );
    return;
}

no Moose::Role;
1;

# ABSTRACT: does Subversion actions for a distribution

__END__

=pod

=for :stopwords Mark Gardner cpan testmatrix url annocpan anno bugtracker rt cpants
kwalitee diff irc mailto metadata placeholders

=encoding utf8

=head1 NAME

Dist::Zilla::Role::Subversion - does Subversion actions for a distribution

=head1 VERSION

version 1.101591

=head1 DESCRIPTION

This role is used within the Subversion plugin to provide common attributes
and defaults.

=head1 ATTRIBUTES

=head2 svn_user

Your Subversion user ID.  Defaults to the cached credentials for your
distribution's working copy.

=head2 svn_password

Your Subversion password.  Defaults to the cached credentials for your
distribution's working copy.

=head2 working_url

URL for the directory currently holding your distribution.  Defaults to your
distribution's repository location as stated in your C<META.yml> file, or
the URL associated with the current working copy.

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
