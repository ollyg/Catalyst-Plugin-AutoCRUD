package CatalystX::ListFramework::Builder::Library::DBIC::Table;

use Moose;
use CatalystX::ListFramework::Builder::Library::Type::Primitives;

has_boxed (
    hash  => [qw/ columns mfks m2ms /],
    array => [qw/ col_list pks /],
);

has 'title' => (
    is => 'rw',
    isa => 'Str',
);

no Moose;
1;
__END__
