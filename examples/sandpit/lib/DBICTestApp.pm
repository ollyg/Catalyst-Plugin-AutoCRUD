package DBICTestApp;

use strict;
use warnings;

use DBI;
#use File::Temp;

#use Class::Data::Inheritable
#;__PACKAGE__->mk_classdata('__dbfile');

use Catalyst qw(AutoCRUD);

#my $dbfile = File::Temp->new( UNLINK => 1, EXLOCK => 0);
# need to stash the filename so File::Temp doesn't clean it immediately
#__PACKAGE__->__dbfile($dbfile);
my $dbfile = 'examples/sandpit/dbictest.sql';

__PACKAGE__->config(
    'Plugin::AutoCRUD' => {
        extjs2 => '/cpacstatic/ext2',
        basepath => '',
        # sites => { default => { frontend => 'skinny' } },
    },
    'Model::AutoCRUD::DBIC' => {
        schema_class => 'DBICTest::Schema',
        connect_info => ["dbi:SQLite:dbname=$dbfile", '', '', {}, { quote_char => q{`}, name_sep => q{.} }],
    },
);
   
__PACKAGE__->setup;
1;
