package SQL::Translator::Filter::AutoCRUD::CatalystModel;



use strict;
use warnings;

sub filter {
    my ($schema, @args) = @_;
    my $cache = shift @args;

    foreach my $tbl ($schema->get_tables) {
        # set catalyst model serving this source
        $tbl->extra(model => $cache->{$tbl->name}->{model});
    }
}

1;
