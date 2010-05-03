package Catalyst::Plugin::AutoCRUD::Model::Backend;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model';

sub dispatch_to {
    my ($self, $c, $target) = @_;
    die 'no target specified for dispatch_to' if !defined $target;

    $c->forward($c->stash->{cpac_backend_store}, $target);
}

1;

__END__
