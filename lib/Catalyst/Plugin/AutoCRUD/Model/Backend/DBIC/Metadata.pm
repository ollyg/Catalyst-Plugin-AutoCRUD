package Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::Metadata;

use strict;
use warnings FATAL => 'all';

our @EXPORT;
BEGIN {
    use base 'Exporter';
    @EXPORT = qw/ dispatch_table source_dispatch_table schema_metadata /;
}

use SQL::Translator;
use SQL::Translator::Filter::AutoCRUD::ReverseRelations;
use SQL::Translator::Filter::AutoCRUD::ExtJSxType;
use SQL::Translator::Filter::AutoCRUD::ColumnsAndPKs;

use Scalar::Util qw(weaken);
use Carp;

# return mapping of url path part to friendly display names
# for each result source within a given schema.
# also generate a cache of which App Model supports which source.
# die if the schema is not supported by this backend.
sub source_dispatch_table {
    my ($self, $c, $schema_path) = @_;
    my $display = {};

    die "failed to load metadata for schema [$schema_path] - is it DBIC?"
        if not exists $self->_schema_cache->{handles}->{$schema_path};
    my $cache = $self->_schema_cache->{handles}->{$schema_path};

    # rebuild retval from cache
    if (exists $cache->{sources}) {
        my $sources = $cache->{sources};
        return { map {($_ => {
                display_name => $sources->{$_}->{display_name},
                editable => $sources->{$_}->{editable},
            })} keys %$sources };
    }

    # find the catalyst model supporting each result source
    my $schema_model = $c->model( $cache->{model} );
    foreach my $moniker ($schema_model->schema->sources) {
        my $source_model = _find_source_model($c, $cache->{model}, $moniker)
            or die "unable to translate moniker [$moniker] into model";
        my $result_source = $c->model($source_model)->result_source;
        my $path = _make_path($result_source);

        $display->{$path} = {
            display_name => _make_label($path),
            editable =>
                not eval { $result_source->isa('DBIx::Class::ResultSource::View') },
        };

        $cache->{sources}->{$path} = {
            model => $source_model,
            display_name => $display->{$path}->{display_name},
            editable => $display->{$path}->{editable},
        };
    }

    # already cached for us
    return $display;
}

# return mapping of uri path part to friendly display names
# for each schema which this backend supports.
# also generate a cache of which App Model supports which schema.
sub dispatch_table {
    my ($self, $c) = @_;
    my ($display, %schema);
    my $cache = {};

    # rebuild retval from cache (copy)
    if (exists $self->_schema_cache->{handles}) {
        $cache = $self->_schema_cache->{handles};

        return { map {{
            display_name => $cache->{$_}->{display_name},
            t => $self->source_dispatch_table($c, $_),
        }} keys %$cache };
    }

    MODEL:
    foreach my $m ($c->models) {
        my $model = eval { $c->model($m) };
        next unless eval { $model->isa('Catalyst::Model::DBIC::Schema') };

        # some models are subclasses of others - skip them
        # this is usually the result source models created automagically
        foreach my $s (keys %schema) {
            if (eval { $model->isa($s) }) {
                delete $schema{$s};
            }
            elsif (eval { $c->model($s)->isa($m) }) {
                next MODEL;
            }
        }
        $schema{$m} = 1;
    }

    foreach my $s (keys %schema) {
        my $path = $c->model($s)->schema->storage->dbh->{Name};

        if ($path =~ m/\W/) {
            # SQLite will return a file name as the "database name"
            $path = lc [ reverse split '::', $s ]->[0];
        }

        $display->{$path} = { display_name => _make_label($path) };
        $cache->{$path} = {
            model        => $s,
            display_name => $display->{$path}->{display_name},
        }
    }

    # source_dispatch_table needs to see the class-data cache
    $self->_schema_cache->{handles} = $cache;

    # now get data for the sources in each schema
    foreach my $p (keys %$cache) {
        $display->{$p}->{t} = $self->source_dispatch_table($c, $p);
    }

    return $display;
}

# generate SQLT Schema instance representing this data schema
sub schema_metadata {
    my ($self, $c) = @_;
    my $db = $c->stash->{cpac_db};

    return $self->_schema_cache->{sqlt}->{$db}
        if exists $self->_schema_cache->{sqlt}->{$db};

    my $sqlt = SQL::Translator->new(
        parser => 'SQL::Translator::Parser::DBIx::Class',
        parser_args => { package =>
            $c->model(
                $self->_schema_cache->{handles}->{$db}->{model}
            )->schema
        },
        filters => [qw/
            SQL::Translator::Filter::AutoCRUD::ReverseRelations
            SQL::Translator::Filter::AutoCRUD::ColumnsAndPKs
            SQL::Translator::Filter::AutoCRUD::ExtJSxType
        /],
        producer => 'SQL::Translator::Producer::POD', # something cheap
    ) or die SQL::Translator->error;

    $sqlt->translate() or die $sqlt->error; # throw result away

    $self->_schema_cache->{sqlt}->{$db} = $sqlt->schema;
    return $sqlt->schema;
}

#sub _build_table_info {
#    my ($c, $cpac, $model, $tab) = @_;
#
#    my $ti = $cpac->{table_info}->{ $model } = {};
#    if ($tab == 1) {
#        # convenience reference to the main table info, for the templates
#        $cpac->{main} = $ti; weaken $cpac->{main};
#    }
#
#    my $source = $c->model($model)->result_source;
#    $ti->{path}    = _rs2path($source);
#    $ti->{title}   = _2title($ti->{path});
#    $ti->{moniker} = $source->source_name;
#    $cpac->{tab_order}->{ $model } = $tab;
#
#    # column and relation info for this table
#    my (%mfks, %sfks, %fks);
#    my @cols = $source->columns;
#
#    my @rels = $source->relationships;
#    foreach my $r (@rels) {
#        my $rel_info = $source->relationship_info($r);
#
#        if ($rel_info->{attrs}->{accessor} eq 'multi') {
#            $mfks{$r} = $source->relationship_info($r);
#            next;
#        }
#
#        # if the self column in the relation condition is a FK, then the
#        # relation type is belongs_to, otherwise it's has_one/might_have
#
#        (my $self_col = (values %{$rel_info->{cond}})[0]) =~ s/^self\.//;
#        my $col_info = $source->column_info($self_col);
#
#        if (exists $col_info->{is_foreign_key} and $col_info->{is_foreign_key} == 1) {
#            # is belongs_to type relation
#            # need to deal with custom accessor name
#            $fks{$r} = $rel_info;
#            @cols = grep {$_ ne $self_col} @cols;
#            $ti->{cols}->{$r}->{masked_col} = $self_col;
#
#            # emit warning about belongs_to relations which are is_nullable
#            # but that do not have a join_type set
#            if (exists $col_info->{is_nullable} and $col_info->{is_nullable} == 1
#                    and !exists $rel_info->{attrs}->{join_type}) {
#                $c->log->error( sprintf(
#                    'AutoCRUD CAUTION!: Relation [%s]->[%s] is of type belongs_to '.
#                    'and is_nullable, but has no join_type set. You will not see '.
#                    'all your data!', $source->source_name, $r
#                ));
#            }
#
#            # emit warning if belongs_to is using a column which does not have
#            # an inflator set. this is caused by belongs_to being issued
#            # before [the last] add_column in the result source.
#            if ($ti->{cols}->{$r}->{masked_col} eq $r
#                    and !exists $col_info->{_inflate_info}) {
#                $c->log->error( sprintf(
#                    'AutoCRUD CAUTION!: Relation [%s]->[%s] is of type belongs_to '.
#                    'but the column [%s] does not have a row inflator. This means '.
#                    'you will not see related row data. Likely cause is belongs_to '.
#                    'being issued before add_column in your result source definition.',
#                        $source->source_name, $r, $self_col
#                ));
#            }
#        }
#        else {
#            # is has_one or might_have type relation
#            # need to grab the FK from the related source
#            $sfks{$r} = $rel_info;
#            (my $foreign_col = (keys %{$rel_info->{cond}})[0]) =~ s/^foreign\.//;
#            $ti->{cols}->{$r}->{foreign_col} = $foreign_col;
#
#            # emit warning about belongs_to relations which refer to columns
#            # without is_foreign_key set (triggers discovery as has_one or
#            # might_have)
#            if (not scalar grep {$_ eq $self_col} $source->primary_columns) {
#                $c->log->error( sprintf(
#                    'AutoCRUD CAUTION!: Relation [%s]->[%s] is of type belongs_to '.
#                    'but is_foreign_key has not been set on column [%s]. You will '.
#                    'have incorrect column data from AutoCRUD until this is fixed!',
#                        $source->source_name, $r, $self_col
#                ));
#            }
#        }
#    }
#
#    # mas_many cols
#    # make friendly human readable title for related tables
#    foreach my $t (keys %mfks) {
#        my $target = _ism2m($source, $t);
#        if ($target) {
#            my $target_source
#                = $source->related_source($t)->related_source($target)->source_name;
#            eval "use Lingua::EN::Inflect::Number";
#            $target_source = Lingua::EN::Inflect::Number::to_PL($target_source)
#                if not $@;
#            $ti->{mfks}->{$t} = _2title( $target_source );
#            $ti->{m2m}->{$t} = $target;
#        }
#        else {
#            $ti->{mfks}->{$t} = _2title( $t );
#        }
#    }
#
#    $ti->{pk} = ($source->primary_columns)[0] || $cols[0];
#    $ti->{col_order} = [
#        $ti->{pk},                                           # primary key
#        (grep {!exists $fks{$_} and $_ ne $ti->{pk}} @cols), # ordinary cols
#    ];
#
#    # consider table columns
#    foreach my $col (@cols) {
#        my $info = $source->column_info($col);
#        next unless defined $info;
#
#        $ti->{cols}->{$col} = {
#            heading      => _2title($col),
#            editable     => ($info->{is_auto_increment} ? 0 : 1),
#            required     => ((exists $info->{is_nullable}
#                                 and $info->{is_nullable} == 0) ? 1 : 0),
#        };
#
#        $ti->{cols}->{$col}->{default_value} = $info->{default_value}
#            if ($info->{default_value} and $ti->{cols}->{$col}->{editable});
#
#        $ti->{cols}->{$col}->{extjs_xtype} = $xtype_for{ lc($info->{data_type}) }
#            if (exists $info->{data_type} and exists $xtype_for{ lc($info->{data_type}) });
#
#        $ti->{cols}->{$col}->{extjs_xtype} = 'textfield'
#            if !exists $ti->{cols}->{$col}->{extjs_xtype}
#                and defined $info->{size} and $info->{size} <= 40;
#    }
#
#    # and FIXME do the same for the FKs which are masking hidden cols
#    foreach my $col (keys %fks) {
#        next unless exists $ti->{cols}->{$col}->{masked_col};
#        my $info = $source->column_info($ti->{cols}->{$col}->{masked_col});
#        next unless defined $info;
#
#        $ti->{cols}->{$col} = {
#            %{$ti->{cols}->{$col}},
#            heading      => _2title($col),
#            editable     => ($info->{is_auto_increment} ? 0 : 1),
#            required     => ((exists $info->{is_nullable}
#                                 and $info->{is_nullable} == 0) ? 1 : 0),
#        };
#
#        $ti->{cols}->{$col}->{default_value} = $info->{default_value}
#            if ($info->{default_value} and $ti->{cols}->{$col}->{editable});
#
#        $ti->{cols}->{$col}->{extjs_xtype} = $xtype_for{ lc($info->{data_type}) }
#            if (exists $info->{data_type} and exists $xtype_for{ lc($info->{data_type}) });
#
#        $ti->{cols}->{$col}->{extjs_xtype} = 'textfield'
#            if !exists $ti->{cols}->{$col}->{extjs_xtype}
#                and defined $info->{size} and $info->{size} <= 40;
#    }
#
#    # extra data for foreign key columns
#    foreach my $col (keys %fks, keys %sfks) {
#
#        # eval to avoid dieing in the presence of dangling rels
#        $ti->{cols}->{$col}->{fk_model}
#            = eval { _moniker2model( $c, $cpac, $c->stash->{cpac_db}, $source->related_source($col)->source_name )};
#        next if !defined $ti->{cols}->{$col}->{fk_model};
#
#        # override the heading for this col to be the foreign table name
#        $ti->{cols}->{$col}->{heading} =
#            _2title( _rs2path( $c->model( $ti->{cols}->{$col}->{fk_model} )->result_source ));
#
#        # all gets a bit complex here, as there are a lot of cases to handle
#
#        # we want to see relation columns unless they're the same as our PK
#        # (which has already been added to the col_order list)
#        push @{$ti->{col_order}}, $col if $col ne $ti->{pk};
#
#        if (exists $sfks{$col}) {
#        # has_one or might_have cols are reverse relations, so pass hint
#            $ti->{cols}->{$col}->{is_rr} = 1;
#        }
#        else {
#        # otherwise mark as a foreign key
#            $ti->{cols}->{$col}->{is_fk} = 1;
#        }
#
#        # relations where the foreign table is the main table are not editable
#        # because the template/extjs will complete the field automatically
#        if ($source->related_source($col)->source_name
#                eq $cpac->{main}->{moniker}) {
#            $ti->{cols}->{$col}->{editable} = 0;
#        }
#        else {
#        # otherwise it's editable, and also let's call ourselves again for FT
#            $ti->{cols}->{$col}->{editable} = 1;
#
#            if ([caller(1)]->[3] !~ m/::_build_table_info$/) {
#                _build_table_info(
#                    $c, $cpac, $ti->{cols}->{$col}->{fk_model}, ++$tab);
#            }
#        }
#    }
#}

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
sub _make_path {
    my $rs = shift;
    return $rs->from if $rs->from =~ m/^\w+$/;

    my $name = $rs->source_name;
    $name =~ s/(\w)([A-Z][a-z0-9])/$1_$2/g;
    return lc $name;
}

# find best table name
sub _rs2path {
    my $rs = shift;
    return $rs->from if $rs->from =~ m/^\w+$/;

    my $name = $rs->source_name;
    $name =~ s/(\w)([A-Z][a-z0-9])/$1_$2/g;
    return lc $name;
}

# find catalyst model serving a DBIC *result source*
sub _find_source_model {
    my ($c, $parent_model, $moniker) = @_;

    foreach my $m ($c->models) {
        my $model = eval { $c->model($m) };
        my $test = eval { $model->result_source->source_name };
        next if !defined $test;

        return $m if $test eq $moniker and $m =~ m/^${parent_model}::/;
    }
    return undef;
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
sub _make_label {
    return join ' ', map ucfirst, split /[\W_]+/, lc shift;
}

# col/table name to human title
sub _2title {
    return join ' ', map ucfirst, split /[\W_]+/, lc shift;
}

1;
__END__
