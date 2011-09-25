#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use DBI;
use File::Temp;

my $sql_file = $ARGV[0] || 'music.sql';

my $dbfile = File::Temp->new( UNLINK => 1, EXLOCK => 0);
my $dbh = DBI->connect("dbi:SQLite:dbname=$dbfile",'','');
open my $sql_fh, $sql_file or die "Can't read SQL file: $!";
{
    local $/ = '';  # empty line(s) are delimeters
    while (<$sql_fh>) {
        $dbh->do($_);
    }
}
close $sql_fh;
$dbh->disconnect;

use DBIx::Class::Schema::Loader 'make_schema_at';
make_schema_at(
    'Dev::Schema',
    { naming => 'current', use_namespaces => 1 }, # debug => 1, },
    [ "dbi:SQLite:dbname=$dbfile",'','' ],
);

use lib './lib';
use SQL::Translator;
use SQL::Translator::Filter::AutoCRUD;

my $t = SQL::Translator->new(
    parser => 'SQL::Translator::Parser::DBIx::Class',
    parser_args => { package => 'Dev::Schema' },
    filters => ['SQL::Translator::Filter::AutoCRUD'],
    producer => 'SQL::Translator::Producer::CustomHTML',
    producer_args => { pretty => 1 },
) or die SQL::Translator->error;
my $out = $t->translate() or die $t->error;

print $out;
