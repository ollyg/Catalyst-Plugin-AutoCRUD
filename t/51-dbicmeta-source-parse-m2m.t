#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';

BEGIN {
    use_ok 'DBICAppM2M';
    use TestApp::M2MSchema;
    use_ok 'CatalystX::ListFramework::Builder::Library::DBIC::Source';
}
my $file = DBICAppM2M->__dbfile;
my $s = TestApp::M2MSchema->connect(
    "dbi:SQLite:dbname=$file"
);

my $o;
$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('Artist')) };
ok $o, "Artist can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('Album')) };
ok $o, "Album can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

