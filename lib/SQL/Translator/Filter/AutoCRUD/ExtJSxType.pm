package SQL::Translator::Filter::AutoCRUD::ExtJSxType;

use strict;
use warnings FATAL => 'all';

my %xtype_for = (
    boolean => 'checkbox',
);

$xtype_for{$_} = 'numberfield' for (
    'bigint',
    'bigserial',
    'dec',
    'decimal',
    'double precision',
    'float',
    'int',
    'integer',
    'mediumint',
    'money',
    'numeric',
    'real',
    'smallint',
    'serial',
    'tinyint',
    'year',
);

$xtype_for{$_} = 'timefield' for (
    'time',
    'time without time zone',
    'time with time zone',
);

$xtype_for{$_} = 'datefield' for (
    'date',
);

$xtype_for{$_} = 'xdatetime' for (
    'datetime',
    'timestamp',
    'timestamp without time zone',
    'timestamp with time zone',
);

sub filter {
    my ($schema, %args) = @_;

    foreach my $tbl ($schema->get_tables, $schema->get_views) {
        # set extjs_xtype on columns
        foreach my $col ($tbl->get_fields) {
            $col->extra(extjs_xtype =>
                $xtype_for{ lc $col->data_type });
        }
    }
}

1;
