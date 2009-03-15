#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';

BEGIN {
    use_ok 'DBICApp';
    use TestApp::Schema;
    use_ok 'CatalystX::ListFramework::Builder::Library::DBIC::Source';
}
my $file = DBICApp->__dbfile;
my $s = TestApp::Schema->connect(
    "dbi:SQLite:dbname=$file"
);

my $o;
$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('Track')) };
ok $o, "Track can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('Artist')) };
ok $o, "Artist can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('Album')) };
ok $o, "Album can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('Copyright')) };
ok $o, "Copyright can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

$o = eval { CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
    source => $s->source('SleeveNotes')) };
ok $o, "SleeveNotes can be parsed";
isa_ok $o, 'CatalystX::ListFramework::Builder::Library::DBIC::Source';

