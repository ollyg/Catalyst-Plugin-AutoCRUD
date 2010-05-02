package Catalyst::Plugin::AutoCRUD::Model::Backend;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model';

sub dispatch_to {
    my ($self, $c, $target) = @_;
    die 'no target specified for dispatch_to' if !defined $target;

    my $backend = $c->stash->{cpac_backend}
        or die 'missing backend specification in dispatch_to - possible bug?';

    my $model = ( ($backend =~ m/^\+/) ? $backend : 'Model::AutoCRUD::Backend::'. $backend );
    $c->forward($model, $target);
}

1;

__END__
