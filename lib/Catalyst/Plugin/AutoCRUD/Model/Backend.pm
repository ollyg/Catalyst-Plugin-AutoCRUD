package Catalyst::Plugin::AutoCRUD::Model::Backend;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model';

sub create {
    my ($self, $c) = @_;
    my $backend = 'Model::AutoCRUD::Backend::'. $c->stash->{cpac_backend};
    $c->forward($backend, 'create');
}

sub list {
    my ($self, $c) = @_;
    my $backend = 'Model::AutoCRUD::Backend::'. $c->stash->{cpac_backend};
    $c->forward($backend, 'list');
}

sub update {
    my ($self, $c) = @_;
    my $backend = 'Model::AutoCRUD::Backend::'. $c->stash->{cpac_backend};
    $c->forward($backend, 'update');
}

sub delete {
    my ($self, $c) = @_;
    my $backend = 'Model::AutoCRUD::Backend::'. $c->stash->{cpac_backend};
    $c->forward($backend, 'delete');
}

sub list_stringified {
    my ($self, $c) = @_;
    my $backend = 'Model::AutoCRUD::Backend::'. $c->stash->{cpac_backend};
    $c->forward($backend, 'list_stringified');
}

1;

__END__
