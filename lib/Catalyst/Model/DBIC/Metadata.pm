package Catalyst::Model::DBIC::Metadata;
use base 'Catalyst::Model::DBIC::Metadata::Base';

use strict;
use warnings FATAL => 'all';

use Carp;

sub list_schemas {
    my ($self) = @_;
    __PACKAGE__->schemas or $self->_load_schemas;
    my $schemas = __PACKAGE__->schemas;

    return {map {( $schemas->{$_}->{title} => $schemas->{$_}->{path} )} keys %$schemas};
}

sub list_sources {
    my ($self, $schema_path) = @_;
    __PACKAGE__->schemas or $self->_load_schemas;

    my $model = __PACKAGE__->schema_for_path->{$schema_path}
        or croak "failed to find schema mapped by [$schema_path]";
    my $schema = __PACKAGE__->schemas->{$model}
        or croak "failed to load schema [$model]";

    exists $schema->{sources} or $self->_load_sources($schema);
    my $sources = $schema->{sources};

    return {map {( $sources->{$_}->{title} => $sources->{$_}->{path} )} keys %$sources};
}

sub get_source {
    my ($self, $schema_path, $source_path) = @_;
    __PACKAGE__->schemas or $self->_load_schemas;

    my $model = __PACKAGE__->schema_for_path->{$schema_path}
        or croak "failed to find schema mapped by [$schema_path]";
    my $schema = __PACKAGE__->schemas->{$model}
        or croak "failed to load schema [$model]";
    exists $schema->{sources} or $self->_load_sources($schema);

    my $moniker = $schema->{moniker_for_path}->{$source_path}
        or croak "failed to find source mapped by [$source_path]";
    my $source = $schema->{sources}->{$moniker}
        or croak "failed to laod source [$moniker]";

    return $source;
}

1;
__END__
