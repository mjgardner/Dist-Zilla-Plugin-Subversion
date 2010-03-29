package Dist::Zilla::Role::Subversion;

# ABSTRACT: does Subversion actions for a distribution

# last changed on:
# $Date$
# $Revision$
# $HeadURL$
# $Author$

use Moose::Role;
with 'Dist::Zilla::Role::Plugin';

use Cwd;
use English qw(-no_match_vars);
use MooseX::Types::URI 'Uri';
use Path::Class qw(dir file);
use Readonly;
use Regexp::DefaultFlags;
use SVN::Client;
use SVN::Wc;
use namespace::autoclean;

=attr svn_user

Your Subversion user ID.  Defaults to the cached credentials for your
distribution's working copy.

=attr svn_password

Your Subversion password.  Defaults to the cached credentials for your
distribution's working copy.

=cut

for my $attr (qw(svn_user svn_password)) {
    has $attr => (
        is        => 'ro',
        isa       => 'Str',
        lazy      => 1,
        predicate => "_has_$attr",
        default   => sub {
            return $ARG[0]->zilla->dzil_app->config_for(
                'Dist::Zilla::App::Command::release')->{$attr};
        },
    );
}

=attr working_url

URL for the directory currently holding your distribution.  Defaults to your
distribution's repository location as stated in your C<META.yml> file, or
the URL associated with the current working copy.

=cut

has 'working_url' => (
    is         => 'ro',
    isa        => Uri,
    coerce     => 1,
    lazy_build => 1,
);

sub _build_working_url {
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

sub _build__base_url {
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

sub _build__svn {
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
        my ( $path, $action, $node_kind, $mime, $state, $revision_num )
            = @ARG;

        $self->log(
            join(
                q{ }, '[SVN]',
                grep {$ARG} (
                    $_ACTION_NAME{$action},  $_STATE_NAME{$state},
                    $_NODE_NAME{$node_kind}, $path,
                    "r$revision_num",
                ),
            )
        );
        return;
    };
}

sub _codes_to_hash {
    my $package = (shift) . q{::};
    no strict 'refs';
    return map { ${ ${$package}{$ARG} } => $ARG }
        grep { ${ ${$package}{$ARG} } }
        keys %{$package};
}

sub _log_commit_info {
    my ( $self, $info, $message ) = @ARG;

    $self->log(
        join q{ }, $info->author(), $message, $info->revision(),
        'on',      $info->date(),
    );
}

no Moose::Role;
1;

__END__

=head1 DESCRIPTION

This role is used within the Subversion plugin to provide common attributes
and defaults.
