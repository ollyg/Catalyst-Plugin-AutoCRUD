package Catalyst::Plugin::AutoCRUD::Model::Metadata::DBIC;
BEGIN {
  $Catalyst::Plugin::AutoCRUD::Model::Metadata::DBIC::VERSION = '1.110731';
}

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

    if (exists $c->stash->{cpac_db} and defined $c->stash->{cpac_db}
        and exists $c->stash->{cpac_table} and defined $c->stash->{cpac_table}
        and exists $self->_schema_cache->{$c->stash->{cpac_db}}->{$c->stash->{cpac_table}}) {

        # we have a cache!
        $c->stash->{cpac_dbtitle} = _2title( $c->stash->{cpac_db} );

        $c->log->debug(sprintf 'autocrud: retrieved cached metadata for db: [%s] table: [%s]',
            $c->stash->{cpac_db}, $c->stash->{cpac_table}) if $c->debug;

        return $self->_schema_cache->{$c->stash->{cpac_db}}->{$c->stash->{cpac_table}};
    }

    # set up databases list, even if only to display to user
    my $cpac = $self->build_db_info($c);

    # no db specified, or unknown db
    return $cpac if !defined $c->stash->{cpac_db}
            or !exists $cpac->{dbpath2model}->{ $c->stash->{cpac_db} };

    $c->stash->{cpac_dbtitle} = _2title( $c->stash->{cpac_db} );
    $self->build_table_info_for_db($c, $cpac, $c->stash->{cpac_db});

    # no table specified, or unknown table
    return $cpac if !defined $c->stash->{cpac_table}
        or !exists $cpac->{path2model}->{ $c->stash->{cpac_db} }->{ $c->stash->{cpac_table} };

    $cpac->{model} = $cpac->{path2model}->{ $c->stash->{cpac_db} }->{ $c->stash->{cpac_table} };

    # build and store in cache
    _build_table_info($c, $cpac, $cpac->{model}, 1);

    $self->_schema_cache->{$c->stash->{cpac_db}}->{$c->stash->{cpac_table}} = $cpac;
    $c->log->debug(sprintf 'autocrud: cached metadata for db: [%s] table: [%s]',
        $c->stash->{cpac_db}, $c->stash->{cpac_table}) if $c->debug;

    return $cpac;
}

sub build_table_info_for_db {
    my ($self, $c, $cpac, $db) = @_;

    # set up tables list, even if only to display to user
    my $try_schema = $c->model( $cpac->{dbpath2model}->{$db} )->schema;
    foreach my $m ($try_schema->sources) {
        my $model = _moniker2model($c, $cpac, $db, $m)
            or croak "unable to translate model [$m] into moniker, bailing out";
        my $source = $c->model($model)->result_source;
        my $p = _rs2path($source);

        $cpac->{table2path}->{$db}->{ _2title($p) } = $p;
        $cpac->{path2model}->{$db}->{ $p } = $model;
        $cpac->{editable}->{$db}->{$p} = not eval { $source->isa('DBIx::Class::ResultSource::View') };
    }
}

sub build_db_info {
    my ($self, $c) = @_;
    my (%cpac, %sources);

    MODEL:
    foreach my $m ($c->models) {
        my $model = eval { $c->model($m) };
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
        my $name = $c->model($s)->schema->storage->dbh->{Name};

        if ($name =~ m/\W/) {
            # SQLite will return a file name as the "database name"
            $name = lc [ reverse split '::', $s ]->[0];            
        }

        $cpac{db2path}->{_2title($name)} = $name;
        $cpac{dbpath2model}->{$name} = $s;
    }

    return \%cpac;
}

sub _build_table_info {
    my ($c, $cpac, $model, $tab) = @_;

    my $ti = $cpac->{table_info}->{ $model } = {};
    if ($tab == 1) {
        # convenience reference to the main table info, for the templates
        $cpac->{main} = $ti; weaken $cpac->{main};
    }

    my $source = $c->model($model)->result_source;
    $ti->{path}    = _rs2path($source);
    $ti->{title}   = _2title($ti->{path});
    $ti->{moniker} = $source->source_name;
    $cpac->{tab_order}->{ $model } = $tab;

    # column and relation info for this table
    my (%mfks, %sfks, %fks);
    my @cols = $source->columns;

    my @rels = $source->relationships;
    foreach my $r (@rels) {
        my $rel_info = $source->relationship_info($r);

        if ($rel_info->{attrs}->{accessor} eq 'multi') {
            $mfks{$r} = $source->relationship_info($r);
            next;
        }

        # if the self column in the relation condition is a FK, then the
        # relation type is belongs_to, otherwise it's has_one/might_have

        (my $self_col = (values %{$rel_info->{cond}})[0]) =~ s/^self\.//;
        my $col_info = $source->column_info($self_col);

        if (exists $col_info->{is_foreign_key} and $col_info->{is_foreign_key} == 1) {
            # is belongs_to type relation
            # need to deal with custom accessor name
            $fks{$r} = $rel_info;
            @cols = grep {$_ ne $self_col} @cols;
            $ti->{cols}->{$r}->{masked_col} = $self_col;

            # emit warning about belongs_to relations which are is_nullable
            # but that do not have a join_type set
            if (exists $col_info->{is_nullable} and $col_info->{is_nullable} == 1
                    and !exists $rel_info->{attrs}->{join_type}) {
                $c->log->error( sprintf(
                    'AutoCRUD CAUTION!: Relation [%s]->[%s] is of type belongs_to '.
                    'and is_nullable, but has no join_type set. You will not see '.
                    'all your data!', $source->source_name, $r
                ));
            }

            # emit warning if belongs_to is using a column which does not have
            # an inflator set. this is caused by belongs_to being issued
            # before [the last] add_column in the result source.
            if ($ti->{cols}->{$r}->{masked_col} eq $r
                    and !exists $col_info->{_inflate_info}) {
                $c->log->error( sprintf(
                    'AutoCRUD CAUTION!: Relation [%s]->[%s] is of type belongs_to '.
                    'but the column [%s] does not have a row inflator. This means '.
                    'you will not see related row data. Likely cause is belongs_to '.
                    'being issued before add_column in your result source definition.',
                        $source->source_name, $r, $self_col
                ));
            }
        }
        else {
            # is has_one or might_have type relation
            # need to grab the FK from the related source
            $sfks{$r} = $rel_info;
            (my $foreign_col = (keys %{$rel_info->{cond}})[0]) =~ s/^foreign\.//;
            $ti->{cols}->{$r}->{foreign_col} = $foreign_col;

            # emit warning about belongs_to relations which refer to columns
            # without is_foreign_key set (triggers discovery as has_one or
            # might_have)
            if (not scalar grep {$_ eq $self_col} $source->primary_columns) {
                $c->log->error( sprintf(
                    'AutoCRUD CAUTION!: Relation [%s]->[%s] is of type belongs_to '.
                    'but is_foreign_key has not been set on column [%s]. You will '.
                    'have incorrect column data from AutoCRUD until this is fixed!',
                        $source->source_name, $r, $self_col
                ));
            }
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

    $ti->{pk} = ($source->primary_columns)[0] || $cols[0];
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

        # eval to avoid dieing in the presence of dangling rels
        $ti->{cols}->{$col}->{fk_model}
            = eval { _moniker2model( $c, $cpac, $c->stash->{cpac_db}, $source->related_source($col)->source_name )};
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
                eq $cpac->{main}->{moniker}) {
            $ti->{cols}->{$col}->{editable} = 0;
        }
        else {
        # otherwise it's editable, and also let's call ourselves again for FT
            $ti->{cols}->{$col}->{editable} = 1;

            if ([caller(1)]->[3] !~ m/::_build_table_info$/) {
                _build_table_info(
                    $c, $cpac, $ti->{cols}->{$col}->{fk_model}, ++$tab);
            }
        }
    }
}

# is this col really part of a many to many?
# test checks for related source having two belongs_to rels *only*,
# and one of them refers to ourselves, and at most one other col (id pk)
sub _ism2m {
    my ($source, $rel) = @_;

    # avoid dieing in the resence of dangling rels
    my $fsource = eval { $source->related_source($rel) }
        or return 0;
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
    my ($c, $cpac, $db, $moniker) = @_;
    my $dbmodel = $cpac->{dbpath2model}->{ $db };

    foreach my $m ($c->models) {
        my $model = eval { $c->model($m) };
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
