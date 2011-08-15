package SQL::Translator::Filter::AutoCRUD::NamesAndPaths;

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

sub filter {
    my ($schema, %args) = @_;

    foreach my $local_table ($schema->get_tables) {
        $local_table = $schema->get_table($local_table)
            if not blessed $local_table;

        $local_table->extra(path_part    => make_path($local_table->name));
        $local_table->extra(display_name => make_label($local_table->name));

        foreach my $local_field ($local_table->get_fields) {
            $local_field = $local_table->get_field($local_field)
                if not blessed $local_field;

            $local_field->extra(path_part    => make_path($local_field->name));

            if ($local_field->is_foreign_key and not $local_field->extra('is_reverse')) {
                $local_field->extra(display_name => make_label($local_field->foreign_key_reference->reference_table));
            }
            else {
                $local_field->extra(display_name => make_label($local_field->name));
            }
        }
    }
}

1;
