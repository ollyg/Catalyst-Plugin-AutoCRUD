package CatalystX::ListFramework::Builder::Library::Type::Primitives;

package Box::Bool;
use Moose;
use MooseX::AttributeHelpers;

has 'storage' => (
    is => 'rw',
    isa => 'Bool',
    metaclass => 'Bool',
    default => sub { 0 },
    provides => { map {$_ => $_} qw/
        set
        unset
        toggle
        not
    /},
);

no Moose;

package Box::Hash;
use Moose;
use MooseX::AttributeHelpers;

has 'storage' => (
    is => 'rw',
    isa => 'HashRef[Any]',
    metaclass => 'Collection::Hash',
    default => sub { {} },
    provides => { map {$_ => $_} qw/
        count
        delete
        empty
        clear
        exists
        get
        keys
        set
        values
        kv
    /},
);

sub dump {
    my $self = shift;
    return map { ( $_ => $self->get($_) ) } $self->keys;
}

no Moose;

package Box::Array;
use Moose;
use MooseX::AttributeHelpers;
use List::Util;

has 'storage' => (
    is => 'rw',
    isa => 'ArrayRef[Any]',
    metaclass => 'Collection::Array',
    default => sub { [] },
    provides => { map {$_ => $_} qw/
        count
        empty
        find
        grep
        map
        elements
        join
        get
        first
        last
        pop
        push
        set
        shift
        unshift
        clear
        delete
        insert
        splice
    /},
);

sub contains {
    my ($self, $item) = @_;
    return List::Util::first {$_ eq $item} $self->elements;
}

no Moose;

package CatalystX::ListFramework::Builder::Library::Type::Primitives;
use Moose;
use Moose::Exporter;

Moose::Exporter->setup_import_methods(
    with_caller => ['has_boxed'],
);

my $class_for = {
    bool  => 'Box::Bool',
    hash  => 'Box::Hash',
    array => 'Box::Array',
};

sub has_boxed {
    my ($caller, %params) = @_;
    my $meta = Class::MOP::Class->initialize($caller);

    for my $type (keys %params) {
        add_client_primitives($meta, $type, %params);
    }
}

sub add_client_primitives {
    my ($meta, $type, %params) = @_;

    confess "value not arrayref\n" if ref $params{$type} ne 'ARRAY';
    confess "unknown type '$type'" if not exists $class_for->{$type};
    my $class = $class_for->{$type};

    for my $name (@{ $params{$type} }) {
        add_client_attribute($meta, $name, $class);
        add_client_getter($meta, $name, $type);
    }
}

sub add_client_attribute {
    my ($meta, $name, $class) = @_;
    return if $meta->has_attribute($name);

    $meta->add_attribute( $name =>
        is => 'rw',
        isa => $class,
        default => sub { $class->new },
    );
}

sub add_client_getter {
    my ($meta, $name, $type) = @_;
    return if $type ne 'hash';
    return if $meta->has_method("get_$name");

    $meta->add_method( "get_$name" =>
        sub { return $_[0]->$name->get($_[1]) }
    );
}

no Moose;
1;
__END__
