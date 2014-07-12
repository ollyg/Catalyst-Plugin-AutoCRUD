#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';

use DBI;
use File::Temp;
use lib './lib';

use DBICTest;
my $schema = DBICTest->init_schema(no_deploy => 1);

use SQL::Translator;
use SQL::Translator::Filter::AutoCRUD;

my $t = SQL::Translator->new(
    parser => 'SQL::Translator::Parser::DBIx::Class',
    parser_args => { dbic_schema => 'DBICTest::Schema' },
    filters => ['SQL::Translator::Filter::AutoCRUD'],
    producer => 'SQL::Translator::Producer::CustomHTML',
    producer_args => { pretty => 1 },
) or die SQL::Translator->error;
my $out = $t->translate() or die $t->error;

print $out;
