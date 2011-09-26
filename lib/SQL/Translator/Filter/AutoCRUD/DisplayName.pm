package SQL::Translator::Filter::AutoCRUD::DisplayName;

use strict;
use warnings FATAL => 'all';

use Scalar::Util 'blessed';
use SQL::Translator::AutoCRUD::Utils;

sub filter {
    my ($schema, @args) = @_;

    $schema->extra(display_name => make_label($schema->name));

    foreach my $table ($schema->get_tables) {
        $table = $schema->get_table($table)
            if not blessed $table;

        $table->extra(display_name => make_label($table->name));

        foreach my $field ($table->get_fields) {
            $field = $table->get_field($field)
                if not blessed $field;

            # avoid reverse relationships, they should have been named already
            if (not $field->extra('is_reverse')) {
                $field->extra(display_name => make_label($field->name));
            }
        }
    }
}

1;
