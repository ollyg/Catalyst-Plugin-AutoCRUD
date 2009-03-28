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
package CatalystX::ListFramework::Builder::Library::Catalyst::Schema;

use Moose;
use CatalystX::ListFramework::Builder::Library::Type::Primitives;
use CatalystX::ListFramework::Builder::Library::Util;
extends 'CatalystX::ListFramework::Builder::Library::DBIC::Schema';

has_boxed (
    hash  => [qw/ moniker_for_path title_for_path /],
);

has 'model' => (
    is => 'rw',
    isa => 'Str',
);

has 'path' => (
    is => 'rw',
    isa => 'Str',
);

sub add_all_sources_metadata {
    my ($self, $c) = @_;

    # set up tables list, even if only to display to user
    foreach my $moniker ($c->model( $self->model )->schema->sources) {
        print STDERR "\tadding source $moniker\n";
        my $model = _moniker2model($c, $moniker, $self->model); # find source model
        my $source = $c->model($model)->result_source; # DBIC ResultSource
        my $path = _rs2path($source);

        $self->moniker_for_path->set($path, $moniker);
        $self->title_for_path->set($path, _2title($path));
        $self->add_source_metadata($source);
    }
}

# find catalyst model which is serving this DBIC result source
sub _moniker2model {
    my ($c, $moniker, $dbmodel) = @_;

    foreach my $m ($c->models) {
        my $model = $c->model($m);
        my $test = eval { $model->result_source->source_name };
        next if !defined $test;

        return $m if $test eq $moniker and $m =~ m/^${dbmodel}::/;
    }
    return undef;
}

no Moose;
1;
__END__
