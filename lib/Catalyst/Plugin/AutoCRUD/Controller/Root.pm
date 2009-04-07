package Catalyst::Plugin::AutoCRUD::Controller::Root;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

sub base : Chained PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{current_view} = 'AutoCRUD::TT';
    $c->stash->{version} = 'CPAC v'
        . $Catalyst::Plugin::AutoCRUD::VERSION;
    $c->stash->{site} = 'default';
}

# =====================================================================

# old back-compat /<schema>/<source> which uses default site
# also good for friendly URLs which use default site

sub no_db : Chained('base') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->forward('no_schema');
}

sub db : Chained('base') PathPart('') CaptureArgs(1) {
    my ($self, $c) = @_;
    $c->forward('schema');
}

sub no_table : Chained('db') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->forward('no_source');
}

sub table : Chained('db') PathPart('') Args(1) {
    my ($self, $c) = @_;
    $c->forward('source');
}

# new RPC-style which specifies site, schema, source explicitly
# like /site/<site>/schema/<schema>/source/<source>

sub site : Chained('base') PathPart CaptureArgs(1) {
    my ($self, $c, $site) = @_;
    $c->stash->{site} = $site;
}

sub no_schema : Chained('site') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->detach('err_message');
}

sub schema : Chained('site') PathPart CaptureArgs(1) {
    my ($self, $c, $db) = @_;
    $c->stash->{db} = $db;
}

sub no_source : Chained('schema') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->detach('err_message');
}

sub source : Chained('schema') PathPart Args(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
    $c->stash->{title} = $c->stash->{lf}->{main}->{title} .' List';
    $c->stash->{template} = 'list.tt';
}

sub ajax : Chained('schema') PathPart('') CaptureArgs(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
}

# =====================================================================

sub do_meta : Private {
    my ($self, $c, $table) = @_;
    $c->stash->{table} = $table;

    $c->forward('AutoCRUD::Metadata');
    $c->detach('err_message') if !defined $c->stash->{lf}->{model};
}

sub err_message : Private {
    my ($self, $c) = @_;
    $c->forward('AutoCRUD::Metadata') if !defined $c->stash->{lf}->{db2path};;
    $c->stash->{template} = 'tables.tt';
}

sub helloworld : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{template} = 'helloworld.tt';
}

sub end : ActionClass('RenderView') {}

1;
__END__
