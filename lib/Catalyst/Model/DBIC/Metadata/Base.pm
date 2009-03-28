package Catalyst::Model::DBIC::Metadata::Base;
use base qw(Catalyst::Model Class::Data::Accessor);

use strict;
use warnings FATAL => 'all';

use NEXT;
use Scalar::Util qw(weaken);

__PACKAGE__->mk_classdata($_) for qw(
    schemas
    schema_for_path
);

sub _load_schemas {
    my ($self) = @_;
    $c->log->debug("_load_schemas") if $c->debug;
    my $c = $self->context;
    my %schemas;
    
    # find models which represent schemas but not sources
    MODEL:
    foreach my $m ($c->models) {
        $c->log->debug("...candidate model [$m]") if $c->debug;
        my $model = $c->model($m);
        next unless eval { $model->isa('Catalyst::Model::DBIC::Schema') };
        foreach my $s (keys %schemas) {
            if (eval { $model->isa($s) }) {
                delete $schemas{$s};
            }
            elsif (eval { $c->model($s)->isa($m) }) {
                next MODEL;
            }
        }
        $schemas{$m} = 1;
    }

    foreach my $s (keys %schemas) {
        $c->log->debug("...inspecting model [$s]") if $c->debug;
        my $name = $c->model($s)->storage->dbh->{Name};

        if ($name =~ m/\W/) {
            # SQLite will return a file name as the "database name"
            $name = lc [ reverse split '::', $s ]->[0];            
        }

        $schemas{$s} = {
            path  => $name,
            title => _2title($name),
            model => $s,
        };
    }

    __PACKAGE__->schemas(\%schemas);
    __PACKAGE__->schema_for_path(map {($schemas{$_}->{path} => $schemas{$_}->{model})} keys %schemas);
}

sub _load_sources {
    my ($self, $schema) = @_;
    $c->log->debug("_load_sources") if $c->debug;
    my $c = $self->context;

    foreach my $moniker ($c->model( $schema->{model} )->schema->sources) {
        $c->log->debug("...adding source [$moniker]") if $c->debug;
        my $model = _moniker2model($c, $moniker, $schema->{model}); # find source model
        my $source = $c->model($model)->result_source; # DBIC ResultSource
        my $path = _rs2path($source);

        # $self->title_for_path->set($path, _2title($path));
        $schema->{moniker_for_path}->{$path} = $moniker;
        $schema->{sources}->{$moniker} = _get_source_metadata($source);
    }
}

sub _add_source_metadata {
    my ($self, $schema) = @_;
    $c->log->debug("_load_sources: [$schema]") if $c->debug;
    my $table = {};
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

# shamelessly taken from Catalyst::Component::ACCEPT_CONTEXT
# it's not used to change the object state, merely to grok components

sub context { return shift->{context} }

sub ACCEPT_CONTEXT {
    my $self    = shift;
    my $context = shift;

    $self->{context} = $context;
    weaken($self->{context});
    
    return $self->NEXT::ACCEPT_CONTEXT($context, @_) || $self;
}

sub COMPONENT {
    my $class = shift;
    my $app   = shift;
    my $args  = shift;
    $args->{context} = $app;
    weaken($args->{context}) if ref $args->{context};
    return $class->NEXT::COMPONENT($app, $args, @_);
}

1;
__END__
