package CatalystX::ListFramework::Builder::Model::Metadata;

use Moose;
use CatalystX::ListFramework::Builder::Library::Catalyst::Schema;
use CatalystX::ListFramework::Builder::Library::Type::Primitives;
use CatalystX::ListFramework::Builder::Library::Util;

# should be instantiated with any DBIC models already set up, because
# we hooked in -after- setup_components. if that isn't the case, either need
# to let users know to put this plugin last, via the docs, or work other
# magic to make sure we are loaded last of all.

has_boxed (
    hash  => [qw/ schemata schema_for_path dbtitle_for_path /],
);

sub COMPONENT {
    my ($self, $c, $params) = @_;
    my %schemata;
    
    # find models which represent schemata but not sources
    MODEL:
    foreach my $m ($c->models) {
        print STDERR "candidate model $m\n";
        my $model = $c->model($m);
        next unless eval { $model->isa('Catalyst::Model::DBIC::Schema') };
        foreach my $s (keys %schemata) {
            if (eval { $model->isa($s) }) {
                delete $schemata{$s};
            }
            elsif (eval { $c->model($s)->isa($m) }) {
                next MODEL;
            }
        }
        $schemata{$m} = 1;
    }

    foreach my $s (keys %schemata) {
        print STDERR "inspecting model $s\n";
        my $name = $c->model($s)->storage->dbh->{Name};

        if ($name =~ m/\W/) {
            # SQLite will return a file name as the "database name"
            $name = lc [ reverse split '::', $s ]->[0];            
        }

        my $new_schema = CatalystX::ListFramework::Builder::Library::Catalyst::Schema->new(
            path  => $name,
            title => _2title($name),
            model => $s,
        );

        $new_schema->add_all_sources_metadata($c);
        $self->schemata->set($s, $new_schema);

        $self->schema_for_path->set($name, $s);
        $self->dbtitle_for_path->set($name, _2title($name));
    }

    return $self;
}

# set stash to contain reference to the relevant source metadata
sub process {
    my ($self, $c) = @_;

    # only one db anyway? pretend the user selected that
    $c->stash->{db_path} = [$self->schema_for_path->keys]->[0]
        if $self->schema_for_path->count == 1;

    # no db specified, or unknown db
    return if !defined $c->stash->{db_path}
        or not $self->schema_for_path->exists( $c->stash->{db_path} );

    $c->stash->{db} = $self->schema_for_path->get( $c->stash->{db_path} );
    my $schema = $self->schemata->get( $c->stash->{db} );

    # no table specified, or unknown table
    return if !defined $c->stash->{table_path}
        or not $schema->moniker_for_path->exists( $c->stash->{table_path} );

    $c->stash->{table}
        = $schema->moniker_for_path->get( $c->stash->{table_path} );

    return $self;
}

no Moose;
1;
__END__
