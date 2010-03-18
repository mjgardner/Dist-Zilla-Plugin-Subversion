package Dist::Zilla::Plugin::ImportToSubversion;

# ABSTRACT: import the dist as a Subversion tag

# last changed on:
# $Date$
# $Revision$
# $HeadURL$
# $Author$

use 5.006;
use Moose;
with 'Dist::Zilla::Role::Releaser';

use Cwd;
use English qw(-no_match_vars);
use MooseX::Types::URI 'Uri';
use Path::Class qw(dir file);
use Regexp::DefaultFlags;
use SVN::Client;
use namespace::autoclean;

for my $attr (qw(svn_user svn_password)) {
    has $attr => (
        is        => 'ro',
        isa       => 'Str',
        lazy      => 1,
        predicate => "_has_$attr",
        default   => sub { $ARG[0]->_from_release_config($attr) },
    );
}

sub _from_release_config {
    my ( $self, $key ) = @ARG;
    return unless my $app = $self->zilla->dzil_app();
    return $app->config_for('Dist::Zilla::App::Command::release')->{$key};
}

for my $attr_base (qw(dists tags)) {
    has "svn_$attr_base"
        . '_url' => (
        is      => 'ro',
        isa     => Uri,
        coerce  => 1,
        lazy    => 1,
        default => sub { $ARG[0]->_make_default_url($attr_base) },
        );
}

sub _make_default_url {
    my ( $self, $url_type ) = @ARG;

    my $url = $self->_from_release_config( "svn_$url_type" . 'url' );
    return URI->new($url) if $url;

    if ( $url = $self->zilla->distmeta->{resources}{repository} ) {
        $url = URI->new($url);
        $url->path_segments( $url->path_segments(), $url_type );
        return $url;
    }

    my $repos_root;
    $self->_context->info(
        getcwd(),
        undef, undef,
        sub {
            $url        = URI->new( $ARG[1]->URL() );
            $repos_root = URI->new( $ARG[1]->repos_root_URL() );
        },
        0
    );

    my @segments = $url->path_segments();
    $url->path_segments(
        @segments[ 0 .. $#segments - !$url->eq($repos_root) ], $url_type );
    return $url;
}

has '_context' => (
    is         => 'ro',
    isa        => 'SVN::Client',
    lazy_build => 1,
);

sub _build__context {
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
            0
        );
    }

    my $ctx_ref = SVN::Client->new(
        auth    => \@auth_baton,
        log_msg => sub { ${ $ARG[0] } = "[__PACKAGE__]" },
    );
    return $ctx_ref;
}

sub release {
    my ( $self, $archive ) = @ARG;
    my %meta = %{ $self->zilla->distmeta() };

    my $dists_url = $self->svn_dists_url->clone->canonical();
    $dists_url->path_segments( $dists_url->path_segments(),
        $archive->basename() );
    $self->_context->import( "$archive", "$dists_url", 1 );
    $self->log("Imported $archive to $dists_url");

    my $dist_dir = getcwd();
    my $tags_url = $self->svn_tags_url->clone->canonical();
    $tags_url->path_segments( $tags_url->path_segments(),
        join '-', @meta{qw(name version)} );
    $self->_context->import( $dist_dir, "$tags_url", 1 );
    $self->log("Imported $dist_dir to $tags_url");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=head1 NAME

Dist::Zilla::Plugin::ImportToSubversion - import the dist to a Subversion repository

=head1 SYNOPSIS

If loaded, this plugin will allow the F<release> command to import the
distribution to a Subversion URL.

=head1 DESCRIPTION

This plugin looks for configuration in your C<dist.ini>:

  [ImportToSubversion]
  svn_user      = YOUR-SVN-USERID
  svn_password  = YOUR-SVN-PASSWORD
  svn_dists_url = http://svn.example.com/path/to/svn/dists/directory
  svn_tags_url  = http://svn.example.com/path/to/svn/tags/directory

If any of these are not provided, they are taken from your cached Subversion
credentials, or in the case of C<svn_url>, from the Repository resource
as provided in your META.yml file.  In the latter case, distributions will
be automatically imported into a "dists" subdirectory of the repository.

=method release

Implemented for L:Dist::Zilla::Role::Releaser|Dist::Zilla::Role::Releaser>
role.  Releases the distribution tarball named in its only argument.

=attr svn_user

Your Subversion user ID.  Defaults to the cached credentials for your
distribution's working copy.

=attr svn_password

Your Subversion password.  Defaults to the cached credentials for your
distribution's working copy.

=attr svn_dists_url

URL for the directory receiving your distribution's tarball.  Defaults to
the "dists" directory within the parent directory of your distribution's
repository location.

=attr svn_tags_url

URL for the tags directory receiving your distribution.  Defaults to
the "tags" directory within the parent directory of your distribution's
repository location.  The actual tag will be your distribution name, followed
by a hyphen, followed by your distribution's version.

=cut
