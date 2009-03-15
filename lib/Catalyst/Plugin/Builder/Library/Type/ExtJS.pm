package CatalystX::ListFramework::Builder::Library::Type::ExtJS;

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    as_is => ['_xtype_for'],
);

sub _xtype_for {

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

    confess "No database type passed to _xtype_for()\n" if !defined $_[0];
    return 'textfield' if !exists $xtype_for{ lc $_[0] };
    return $xtype_for{ lc $_[0] };
}

no Moose;
1;
__END__
