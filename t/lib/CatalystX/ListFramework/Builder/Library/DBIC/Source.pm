package CatalystX::ListFramework::Builder::Library::DBIC::Source;

use Moose;
use CatalystX::ListFramework::Builder::Library::Type::Primitives;
use CatalystX::ListFramework::Builder::Library::Type::ExtJS;
use CatalystX::ListFramework::Builder::Library::DBIC::Table;
use CatalystX::ListFramework::Builder::Library::DBIC::Column;
use CatalystX::ListFramework::Builder::Library::Util;

has_boxed (
    hash  => [qw/ tables /],
    array => [qw/ tabs _related_sources /],
);

has 'source' => (
    is  => 'ro',
    isa => 'DBIx::Class::ResultSource',
    required => 1,
);

sub schema {
    return $_[0]->source->schema;
}

sub main_table {
    my $self = shift;
    return $self->tables->get( $self->source->source_name );
}

sub BUILD {
    my ($self, $params) = @_;
    $self->_build_table_info( $self->source->source_name );
    $self->_build_table_info( $_ ) for $self->_related_sources->elements;
}

sub _build_table_info {
    my ($self, $moniker) = @_;
    $ENV{LFB_DEBUG} && print STDERR "table for $moniker\n";
    my $table = CatalystX::ListFramework::Builder::Library::DBIC::Table->new;
    my $source = $self->schema->source($moniker);

    # column and relation caches for this run through
    my (%mfks, %sfks, %fks);
    my @cols = $source->columns;

    my @rels = $source->relationships;
    foreach my $r (@rels) {
        my $type = $source->relationship_info($r)->{attrs}->{accessor};
        $ENV{LFB_DEBUG} && print STDERR "\trelation $r of type $type\n";

        if ($type eq 'multi') {
            $mfks{$r} = $source->relationship_info($r);
        }
        elsif ($type eq 'single') {
            $sfks{$r} = $source->relationship_info($r);
        }
        else { # filter
            $fks{$r} = $source->relationship_info($r);
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
            $table->mfks->set($t, _2title( $target_source ));
            $table->m2ms->set($t, $target);
        }
        else {
            $table->mfks->set($t, _2title( $t ));
        }
    }

    $table->pks->push( $source->primary_columns );
    $table->col_list->push(
        $table->pks->elements,                                            # primary keys
        (grep {not(exists $fks{$_} or $table->pks->contains($_))} @cols), # ordinary cols
    );

    # create column stubs in the table
    foreach my $c (@cols, keys %sfks) {
        $table->columns->set($c,
            CatalystX::ListFramework::Builder::Library::DBIC::Column->new);
        $ENV{LFB_DEBUG} && print STDERR "\tcolumn $c created\n";
    }

    # consider table columns
    foreach my $c (@cols) {
        my $info = $source->column_info($c) or next;
        my $column = $table->columns->get($c);
        $ENV{LFB_DEBUG} && print STDERR "\t\tcolumn $c being configured\n";

        $column->heading( _2title($c) );
        $column->editable( ($info->{is_auto_increment} ? 0 : 1) );
        $column->required( ((exists $info->{is_nullable}
                                and $info->{is_nullable} == 0) ? 1 : 0) );

        $column->extjs_xtype( _xtype_for($info->{data_type}) )
            if exists $info->{data_type};
        $column->default_value( $info->{default_value} )
            if ($info->{default_value} and $column->editable);

        $table->columns->set($c, $column);
    }

    # extra data for foreign key columns
    foreach my $c (keys %fks, keys %sfks) {
        $ENV{LFB_DEBUG} && print STDERR "\t\tfurther processing column $c\n";
        my $column = $table->columns->get($c);

        # link to other entry in $self->tables()
        $column->fk_moniker( $source->related_source($c)->source_name );

        # override the heading for this col to be the foreign table name
        $column->heading( _2title( _rs2path($source->related_source($c)) ) );

        # we want to see relation columns unless they're part of our PK
        # (which has already been added to the col_order list)
        $table->col_list->push($c) if not $table->pks->contains($c);

        if (exists $sfks{$c}) {
        # has_one or might_have cols are reverse relations, so pass hint
            $column->is_rr(1);
        }
        else {
        # otherwise mark as a foreign key
            $column->is_fk(1);
        }

        # relations where the foreign table is the main table are not editable
        # because the template/extjs will complete the field automatically
        if ($source->related_source($c)->source_name eq $self->source->source_name) {
            $column->editable(0);
        }
        else {
        # otherwise it's editable (and this sub will be run for related table)
            $column->editable(1);
            $self->_related_sources->push( $source->related_source($c)->source_name );
        }
    }

    $table->title( _2title(_rs2path($source)) );
    $self->tabs->push($moniker);
    $self->tables->set($moniker, $table);
}

no Moose;
1;
__END__
