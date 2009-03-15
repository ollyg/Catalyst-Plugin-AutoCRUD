package CatalystX::ListFramework::Builder::Library::DBIC::Schema;

use Moose;
use CatalystX::ListFramework::Builder::Library::Type::Primitives;
use CatalystX::ListFramework::Builder::Library::DBIC::Source;

has_boxed (
    hash  => [qw/ sources /],
);

has 'title' => (
    is => 'rw',
    isa => 'Str',
);

sub add_source_metadata {
    my ($self, $source) = @_;
    my $s_meta = CatalystX::ListFramework::Builder::Library::DBIC::Source->new(
        source => $source );
    $self->sources->set($source->source_name, $s_meta);
}

no Moose;
1;
__END__
