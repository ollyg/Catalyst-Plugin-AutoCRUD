package SQL::Translator::Filter::AutoCRUD;

use strict;
use warnings FATAL => 'all';
use Scalar::Util 'blessed';

sub make_label { return join ' ', map ucfirst, split /[\W_]+/, lc shift }

sub make_path {
    my $item = shift;
    return $item if $item =~ m/^\w+$/;

    $item =~ s/(\w)([A-Z][a-z0-9])/$1_$2/g;
    return lc $item;
}

sub add_to_rels_at {
    my ($loc, $config) = @_;
    use SQL::Translator::Schema::Constraint;
    use Lingua::EN::Inflect::Number;

    #use Data::Dumper;
    #print STDERR Dumper [@_];

    my $constraint = SQL::Translator::Schema::Constraint->new($config);
    my $name = $config->{name};

    if ($config->{extra}->{dbic_type} =~ m/^(?:has_many|many_to_many)$/) {
        $name = Lingua::EN::Inflect::Number::to_PL($name);
        $constraint->name($name);
    }
    if (exists $loc->{_relationships}->{$name}
        and $config->{extra}->{dbic_type} ne 'many_to_many') {
        # we have two rels between same two tables
        # rename each to refer to the rel on which it is based

        my $orig_name = $name .'_via_'. $loc->{_relationships}->{$name}->{extra}->{via};
        $loc->{_relationships}->{$name}->name($orig_name);
        $loc->{_relationships}->{$name}->{extra}->{label} = make_label($orig_name);
        $loc->{_relationships}->{$orig_name} = delete $loc->{_relationships}->{$name};

        $name = $name .'_via_'. $config->{extra}->{via};
        $constraint->name($name);
    }

    $constraint->extra->{label} = make_label($name);
    $loc->{_relationships}->{$name} = $constraint;
}

sub filter {
    my ($schema, %args) = @_;

    foreach my $local_table ($schema->get_tables) {
        $local_table = $schema->get_table($local_table)
            if not blessed $local_table;

        $local_table->extra->{label} = make_label($local_table->name);
        $local_table->extra->{path_part} = make_path($local_table->name);

        foreach my $local_field ($local_table->get_fields) {
            $local_field = $local_table->get_field($local_field)
                if not blessed $local_field;

            $local_field->extra->{label} = make_label($local_field->name);
            $local_field->extra->{path_part} = make_path($local_field->name);
        }

        use SQL::Translator::Schema::Constants 'FOREIGN_KEY';
        foreach my $c ($local_table->get_constraints) {
            next unless $c->type eq FOREIGN_KEY;
            next if $local_table->extra->{seen}->{$c->name}++;

            my $remote_table = $c->reference_table;
            $remote_table = $schema->get_table($remote_table)
                if not blessed $remote_table;

            if (scalar (grep {not ($_->is_unique)} $c->fields) == 0) {
                add_to_rels_at(scalar $remote_table->extra, {
                    name => $local_table->name,
                    reference_table => $local_table->name,
                    reference_fields => [$c->fields],
                    extra => {
                        dbic_type => 'might_have',
                        via => $c->name,
                        from => $local_table->name,
                    }
                });
            }
            else {
                # we could be sat on a m2m link table
                my @remote_names = ();
                my $is_m2m = 0;

                foreach my $rel ($local_table->get_constraints) {
                    next unless $rel->type eq FOREIGN_KEY;
                    next unless scalar (grep {$_->is_nullable} $rel->fields) == 0;
                    push @remote_names, $rel->reference_table.'';
                }

                my %remote_lkp = (@remote_names, reverse @remote_names);

                # must be two rels to different tables to have two keys
                if (scalar keys %remote_lkp == 2) {
                    foreach my $left (keys %remote_lkp) {
                        add_to_rels_at(scalar $schema->get_table($left)->extra, {
                            name => $remote_lkp{$left},
                            reference_table => $remote_lkp{$left},
                            reference_fields => [$schema->get_table($remote_lkp{$left})->primary_key->fields],
                            extra => {
                                dbic_type => 'many_to_many',
                                via => $c->name,
                                from => $local_table->name,
                            },
                        });
                    }
                    ++$is_m2m;
                }

                if (not $is_m2m) {
                    add_to_rels_at(scalar $remote_table->extra, {
                        name => $local_table->name,
                        reference_table => $local_table->name,
                        reference_fields => [$c->fields],
                        extra => {
                            dbic_type => 'has_many',
                            via => $c->name,
                            from => $local_table->name,
                        }
                    });
                }
            }
        } # constraints
    } # tables
} # sub filter

1;
