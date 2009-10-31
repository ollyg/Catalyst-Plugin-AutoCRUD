package Catalyst::Plugin::AutoCRUD::Model::Metadata;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model';
use Scalar::Util qw(weaken);
use Carp;

__PACKAGE__->mk_classdata(_schema_cache => {});

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

sub process {
    my ($self, $c) = @_;

    if (exists $c->stash->{db} and defined $c->stash->{db}
        and exists $c->stash->{table} and defined $c->stash->{table}
        and exists $self->_schema_cache->{$c->stash->{db}}->{$c->stash->{table}}) {

        # we have a cache!
        $c->stash->{dbtitle} = _2title( $c->stash->{db} );
        $c->stash->{lf} = $self->_schema_cache->{$c->stash->{db}}->{$c->stash->{table}};
        $c->log->debug(sprintf 'autocrud: retrieved cached metadata for db: [%s] table: [%s]',
            $c->stash->{db}, $c->stash->{table}) if $c->debug;

        weaken $c->stash->{lf};
        return $self;
    }

    # set up databases list, even if only to display to user
    my $lf = $c->stash->{lf} = $self->build_db_info($c);

    # only one db anyway? pretend the user selected that
    $c->stash->{db} = [keys %{$lf->{dbpath2model}}]->[0]
        if scalar keys %{$lf->{dbpath2model}} == 1;

    # no db specified, or unknown db
    return if !defined $c->stash->{db}
            or !exists $lf->{dbpath2model}->{ $c->stash->{db} };

    $c->stash->{dbtitle} = _2title( $c->stash->{db} );
    $self->build_table_info_for_db($c, $lf, $c->stash->{db});

    # no table specified, or unknown table
    return if !defined $c->stash->{table}
        or !exists $lf->{path2model}->{ $c->stash->{db} }->{ $c->stash->{table} };

    $lf->{model} = $lf->{path2model}->{ $c->stash->{db} }->{ $c->stash->{table} };

    # build and store in cache
    _build_table_info($c, $lf, $lf->{model}, 1);

    $self->_schema_cache->{$c->stash->{db}}->{$c->stash->{table}} = $lf;
    $c->log->debug(sprintf 'autocrud: cached metadata for db: [%s] table: [%s]',
        $c->stash->{db}, $c->stash->{table}) if $c->debug;

    weaken $c->stash->{lf};
    return $self;
}

sub build_table_info_for_db {
    my ($self, $c, $lf, $db) = @_;

    # set up tables list, even if only to display to user
    my $try_schema = $c->model( $lf->{dbpath2model}->{$db} )->schema;
    foreach my $m ($try_schema->sources) {
        my $model = _moniker2model($c, $lf, $db, $m)
            or croak "unable to translate model [$m] into moniker, bailing out";
        my $p = _rs2path($c->model($model)->result_source);

        $lf->{table2path}->{ _2title($p) } = $p;
        $lf->{path2model}->{$db}->{ $p } = $model;
    }
}

sub build_db_info {
    my ($self, $c) = @_;
    my (%lf, %sources);

    MODEL:
    foreach my $m ($c->models) {
        my $model = $c->model($m);
        next unless eval { $model->isa('Catalyst::Model::DBIC::Schema') };
        foreach my $s (keys %sources) {
            if (eval { $model->isa($s) }) {
                delete $sources{$s};
            }
            elsif (eval { $c->model($s)->isa($m) }) {
                next MODEL;
            }
        }
        $sources{$m} = 1;
    }

    foreach my $s (keys %sources) {
        my $name = $c->model($s)->storage->dbh->{Name};

        if ($name =~ m/\W/) {
            # SQLite will return a file name as the "database name"
            $name = lc [ reverse split '::', $s ]->[0];            
        }

        $lf{db2path}->{_2title($name)} = $name;
        $lf{dbpath2model}->{$name} = $s;
    }

    return \%lf;
}

sub _build_table_info {
    my ($c, $lf, $model, $tab) = @_;

    my $ti = $lf->{table_info}->{ $model } = {};
    if ($tab == 1) {
        # convenience reference to the main table info, for the templates
        $lf->{main} = $ti; weaken $lf->{main};
    }

    my $source = $c->model($model)->result_source;
    $ti->{path}    = _rs2path($source);
    $ti->{title}   = _2title($ti->{path});
    $ti->{moniker} = $source->source_name;
    $lf->{tab_order}->{ $model } = $tab;

    # column and relation info for this table
    my (%mfks, %sfks, %fks);
    my @cols = $source->columns;

    my @rels = $source->relationships;
    foreach my $r (@rels) {
        my $type = $source->relationship_info($r)->{attrs}->{accessor};
        if ($type eq 'multi') {
            $mfks{$r} = $source->relationship_info($r);
        }
        # the join_type is a bit heuristic but it's difficult to differentiate
        # the belongs_to with a custom accessor name, from the has_one/might_have
        elsif ($type eq 'single'
                and exists $source->relationship_info($r)->{attrs}->{join_type}) {
            $sfks{$r} = $source->relationship_info($r);
        }
        else { # filter
            $fks{$r} = $source->relationship_info($r);
            # if this is a belongs_to with custom accessor, hide the orig col
            (my $src_col = (values %{$source->relationship_info($r)->{cond}})[0]) =~ s/^self\.//;
            @cols = grep {$_ !~ m/^$src_col$/} @cols;
            $ti->{cols}->{$r}->{masked_col} = $src_col;
        }
    }

    # mas_many cols
    # make friendly human readable title for related tables
    foreach my $t (keys %mfks) {
        my $target = _ism2m($source, $t);
        if ($target) {
            my $target_source
                = $source->related_source($t)->related_source($target)->source_name;
            eval "use Lingua::EN::Inflect::Number";
            $target_source = Lingua::EN::Inflect::Number::to_PL($target_source)
                if not $@;
            $ti->{mfks}->{$t} = _2title( $target_source );
            $ti->{m2m}->{$t} = $target;
        }
        else {
            $ti->{mfks}->{$t} = _2title( $t );
        }
    }

    $ti->{pk} = ($source->primary_columns)[0];
    $ti->{col_order} = [
        $ti->{pk},                                           # primary key
        (grep {!exists $fks{$_} and $_ ne $ti->{pk}} @cols), # ordinary cols
    ];

    # consider table columns
    foreach my $col (@cols) {
        my $info = $source->column_info($col);
        next unless defined $info;

        $ti->{cols}->{$col} = {
            heading      => _2title($col),
            editable     => ($info->{is_auto_increment} ? 0 : 1),
            required     => ((exists $info->{is_nullable}
                                 and $info->{is_nullable} == 0) ? 1 : 0),
        };

        $ti->{cols}->{$col}->{default_value} = $info->{default_value}
            if ($info->{default_value} and $ti->{cols}->{$col}->{editable});

        $ti->{cols}->{$col}->{extjs_xtype} = $xtype_for{ lc($info->{data_type}) }
            if (exists $info->{data_type} and exists $xtype_for{ lc($info->{data_type}) });

        $ti->{cols}->{$col}->{extjs_xtype} = 'textfield'
            if !exists $ti->{cols}->{$col}->{extjs_xtype}
                and defined $info->{size} and $info->{size} <= 40;
    }

    # and FIXME do the same for the FKs which are masking hidden cols
    foreach my $col (keys %fks) {
        next unless exists $ti->{cols}->{$col}->{masked_col};
        my $info = $source->column_info($ti->{cols}->{$col}->{masked_col});
        next unless defined $info;

        $ti->{cols}->{$col} = {
            %{$ti->{cols}->{$col}},
            heading      => _2title($col),
            editable     => ($info->{is_auto_increment} ? 0 : 1),
            required     => ((exists $info->{is_nullable}
                                 and $info->{is_nullable} == 0) ? 1 : 0),
        };

        $ti->{cols}->{$col}->{default_value} = $info->{default_value}
            if ($info->{default_value} and $ti->{cols}->{$col}->{editable});

        $ti->{cols}->{$col}->{extjs_xtype} = $xtype_for{ lc($info->{data_type}) }
            if (exists $info->{data_type} and exists $xtype_for{ lc($info->{data_type}) });

        $ti->{cols}->{$col}->{extjs_xtype} = 'textfield'
            if !exists $ti->{cols}->{$col}->{extjs_xtype}
                and defined $info->{size} and $info->{size} <= 40;
    }

    # extra data for foreign key columns
    foreach my $col (keys %fks, keys %sfks) {

        $ti->{cols}->{$col}->{fk_model}
            = _moniker2model( $c, $lf, $c->stash->{db}, $source->related_source($col)->source_name );
        next if !defined $ti->{cols}->{$col}->{fk_model};

        # override the heading for this col to be the foreign table name
        $ti->{cols}->{$col}->{heading} =
            _2title( _rs2path( $c->model( $ti->{cols}->{$col}->{fk_model} )->result_source ));

        # all gets a bit complex here, as there are a lot of cases to handle

        # we want to see relation columns unless they're the same as our PK
        # (which has already been added to the col_order list)
        push @{$ti->{col_order}}, $col if $col ne $ti->{pk};

        if (exists $sfks{$col}) {
        # has_one or might_have cols are reverse relations, so pass hint
            $ti->{cols}->{$col}->{is_rr} = 1;
        }
        else {
        # otherwise mark as a foreign key
            $ti->{cols}->{$col}->{is_fk} = 1;
        }

        # relations where the foreign table is the main table are not editable
        # because the template/extjs will complete the field automatically
        if ($source->related_source($col)->source_name
                eq $lf->{main}->{moniker}) {
            $ti->{cols}->{$col}->{editable} = 0;
        }
        else {
        # otherwise it's editable, and also let's call ourselves again for FT
            $ti->{cols}->{$col}->{editable} = 1;

            if ([caller(1)]->[3] !~ m/::_build_table_info$/) {
                _build_table_info(
                    $c, $lf, $ti->{cols}->{$col}->{fk_model}, ++$tab);
            }
        }
    }
}

# is this col really part of a many to many?
# test checks for related source having two belongs_to rels *only*,
# and one of them refers to ourselves, and at most one other col (id pk)
sub _ism2m {
    my ($source, $rel) = @_;

    my $fsource = $source->related_source($rel);
    my @frels = $fsource->relationships;
    return 0 if scalar @frels != 2 or scalar $fsource->columns > 3;

    my $reverse_rel_okay = 0;
    my $target;

    foreach my $frel (@frels) {
        return 0
            if $fsource->relationship_info($frel)->{attrs}->{accessor} ne 'filter';

        if ($fsource->related_source($frel)->source_name eq $source->source_name) {
            $reverse_rel_okay = 1;
        }
        else {
            $target = $frel;
        }
    }
    return 0 if not $reverse_rel_okay;
    return $target;
}

# find best table name
sub _rs2path {
    my $rs = shift;
    return $rs->from if $rs->from =~ m/^\w+$/;

    my $name = $rs->source_name;
    $name =~ s/(\w)([A-Z][a-z0-9])/$1_$2/g;
    return lc $name;
}

# find catalyst model which is serving this DBIC result source
sub _moniker2model {
    my ($c, $lf, $db, $moniker) = @_;
    my $dbmodel = $lf->{dbpath2model}->{ $db };

    foreach my $m ($c->models) {
        my $model = $c->model($m);
        my $test = eval { $model->result_source->source_name };
        next if !defined $test;

        return $m if $test eq $moniker and $m =~ m/^${dbmodel}::/;
    }
    return undef;
}

# col/table name to human title
sub _2title {
    return join ' ', map ucfirst, split /[\W_]+/, lc shift;
}

1;
__END__
