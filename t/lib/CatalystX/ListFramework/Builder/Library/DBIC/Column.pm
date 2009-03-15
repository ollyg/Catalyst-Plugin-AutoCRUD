package CatalystX::ListFramework::Builder::Library::DBIC::Column;

use Moose;

has 'heading' => (
    is => 'rw',
    isa => 'Str',
);

has 'extjs_xtype' => (
    is => 'rw',
    isa => 'Str',
    default => 'textfield',
);

has 'default_value' => (
    is => 'rw',
    isa => 'Str',
    default => undef,
);

has 'fk_moniker' => (
    is => 'rw',
    isa => 'Str',
    default => undef,
);

has 'is_rr' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'is_fk' => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
);

has 'required' => (
    is => 'rw',
    isa => 'Bool',
);

has 'editable' => (
    is => 'rw',
    isa => 'Bool',
);

no Moose;
1;
