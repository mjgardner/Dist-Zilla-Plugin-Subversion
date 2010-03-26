#!perl

use Cwd;
use Dist::Zilla;
use English qw(-no_match_vars);
use File::Temp;
use Modern::Perl;
use Path::Class qw(dir file);
use SVN::Client;
use SVN::Repos;
use Test::Most;
use Test::Moose;
use Text::Template;
use Readonly;

# last changed on:
# $Date$
# $Revision$
# $HeadURL$
# $Author$

our $MODULE;
Readonly my $TESTS => 7;

BEGIN { Readonly our $MODULE => 'Dist::Zilla::Plugin::Subversion::Tag' }
BEGIN { use_ok($MODULE) }

isa_ok( $MODULE, 'Moose::Object', $MODULE );
for (qw(svn_user svn_password working_url tag_url)) {
    has_attribute_ok( $MODULE, $ARG, "$MODULE has the $ARG attribute" );
}
can_ok( $MODULE, qw(after_release) );

my $wc       = File::Temp->newdir();
my $repo_dir = File::Temp->newdir();
my $repo_uri = URI::file->new_abs("$repo_dir");
{
    ## no critic (ProhibitCallsToUnexportedSubs)
    my $repos = SVN::Repos::create( "$repo_dir", undef, undef, undef, undef );
}
dir( "$wc", 'trunk' )->mkpath();
my $ini_file = file( "$wc", qw(trunk dist.ini) );
my $ini_template
    = Text::Template->new( type => 'string', source => <<'END_INI');
name     = test
author   = test user
abstract = test release
license  = BSD
version  = 1.{$version}
copyright_holder = test holder

[FakeRelease]
[Subversion::Tag]
{ join "\n", @ini_lines }
END_INI

my $fh = $ini_file->openw();
print $fh $ini_template->fill_in();
close $fh;
dir( "$wc", 'tags' )->mkpath();

my $test_client = SVN::Client->new();
$test_client->import( "$wc", "$repo_uri", 0 );
for (qw(trunk tags)) { dir( "$wc", $ARG )->rmtree() }
$test_client->checkout( "$repo_uri/trunk", "$wc", 'HEAD', 1 );

my %plugin_test = (
    from_checkout => [],
    working_only  => ["working_url = $repo_uri/trunk"],
    tag_only      => ["tag_url     = $repo_uri/tags"],
);
$plugin_test{full_ini} = \@plugin_test{qw(working_only tag_only)};
eval { require Dist::Zilla::Plugin::Repository; 1 }
    and $plugin_test{repository} = ['[Repository]'];

my $old_dir = getcwd();
chdir("$wc");
my $version = 0;
while ( my ( $test_name, $plugins_ref ) = each %plugin_test ) {
    my $ini_fh = file( "$wc", 'dist.ini' )->openw();
    print $ini_fh $ini_template->fill_in(
        hash => { ini_lines => $plugins_ref, version => $version++ } );
    close $ini_fh;
    my $zilla = Dist::Zilla->from_config();
    lives_ok( sub { $zilla->release() }, $test_name );
}
chdir $old_dir;
done_testing( $TESTS + keys %plugin_test );
