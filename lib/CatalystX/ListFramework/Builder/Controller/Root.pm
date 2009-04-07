package CatalystX::ListFramework::Builder::Controller::Root;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

sub base : Chained PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{current_view} = 'LFB::TT';
    $c->stash->{version} = 'LFB v'
        . $CatalystX::ListFramework::Builder::VERSION;
}

sub db_picker : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->detach('err_message');
}

sub db : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c, $db) = @_;
    $c->stash->{db} = $db;
}

sub no_table : Chained('db') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->detach('err_message');
}

sub do_meta : Private {
    my ($self, $c, $table) = @_;
    $c->stash->{table} = $table;

    $c->forward('LFB::Metadata');
    $c->detach('err_message') if !defined $c->stash->{lf}->{model};
}

sub main : Chained('db') PathPart('') Args(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
    $c->stash->{title} = $c->stash->{lf}->{main}->{title} .' List';
    $c->stash->{template} = 'list.tt';
}

sub ajax : Chained('db') PathPart('') CaptureArgs(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
}

sub err_message : Private {
    my ($self, $c) = @_;
    $c->forward('LFB::Metadata') if !defined $c->stash->{lf}->{db2path};;
    $c->stash->{template} = 'tables.tt';
}

sub helloworld : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'helloworld.tt';
}

sub end : ActionClass('RenderView') {}

1;
__END__
