package CatalystX::ListFramework::Builder::Library::Util;

use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    as_is => [qw/ _ism2m _rs2path _2title /],
);

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

# col/table name to human title
sub _2title {
    return join ' ', map ucfirst, split /[\W_]+/, lc shift;
}

no Moose;
1;
__END__

