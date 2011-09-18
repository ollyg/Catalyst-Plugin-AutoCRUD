package SQL::Translator::Filter::AutoCRUD::DisplayName;

use strict;
use warnings FATAL => 'all';

use Scalar::Util 'blessed';

sub make_label { return join ' ', map ucfirst, split /[\W_]+/, lc shift }

sub filter {
    my ($schema, @args) = @_;

    $schema->extra(display_name => make_label($schema->name));

    foreach my $local_table ($schema->get_tables) {
        $local_table = $schema->get_table($local_table)
            if not blessed $local_table;

        $local_table->extra(display_name => make_label($local_table->name));

        foreach my $local_field ($local_table->get_fields) {
            $local_field = $local_table->get_field($local_field)
                if not blessed $local_field;

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
