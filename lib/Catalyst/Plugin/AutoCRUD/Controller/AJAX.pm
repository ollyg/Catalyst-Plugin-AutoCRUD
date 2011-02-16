package Catalyst::Plugin::AutoCRUD::Controller::AJAX;
BEGIN {
  $Catalyst::Plugin::AutoCRUD::Controller::AJAX::VERSION = '1.110471';
}

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

# we're going to check that calls to this RPC operation are allowed
sub acl : Private {
    my ($self, $c) = @_;
    my $site = $c->stash->{cpac_site};
    my $db = $c->stash->{cpac_db};
    my $table = $c->stash->{cpac_table};

    my $acl_for = {
        create   => 'create_allowed',
        update   => 'update_allowed',
        'delete' => 'delete_allowed',
        dumpmeta      => 'dumpmeta_allowed',
        dumpmeta_html => 'dumpmeta_allowed',
    };
    my $action = [split m{/}, $c->action]->[-1];
    my $acl = $acl_for->{ $action } or return;

    if ($c->stash->{site_conf}->{$db}->{$table}->{$acl} ne 'yes') {
        my $msg = "Access forbidden by configuration to [$site]->[$db]->[$table]->[$action]";
        $c->log->debug($msg) if $c->debug;

        $c->response->content_type('text/plain; charset=utf-8');
        $c->response->body($msg);
        $c->response->status('403');
        $c->detach();
    }
}

sub base : Chained('/autocrud/root/call') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward('acl');

    my $page   = $c->req->params->{'page'}  || 1;
    my $limit  = $c->req->params->{'limit'} || 10;
    my $sortby = $c->req->params->{'sort'}  || $c->stash->{cpac_meta}->{main}->{pk};
    (my $dir   = $c->req->params->{'dir'}   || 'ASC') =~ s/\s//g;

    @{$c->stash}{qw/ cpac_page cpac_limit cpac_sortby cpac_dir /}
        = ($page, $limit, $sortby, $dir);

    $c->stash->{current_view} = 'AutoCRUD::JSON';
}

sub end : ActionClass('RenderView') {}

sub create : Chained('base') Args(0) {
    my ($self, $c) = @_; 
    $c->forward($c->stash->{cpac_backend_store}, 'create');
}

sub list : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac_backend_store}, 'list');
}

sub update : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac_backend_store}, 'update');
}

sub delete : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac_backend_store}, 'delete');
}

sub list_stringified : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward($c->stash->{cpac_backend_store}, 'list_stringified');
}

# send our generated config back in JSON for debugging
sub dumpmeta : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{json_data} = {
        cpac => $c->stash->{cpac_meta},
        site_conf => $c->stash->{site_conf},
    };

    return $self;
}

# send our generated config back to the user in HTML
sub dumpmeta_html : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my $msg = $c->stash->{cpac_version} . ' Metadata Debug Output';

    $c->debug(1);
    $c->error([ $msg ]);
    $c->stash->{dumpmeta} = 1;
    $c->response->body($msg);

    return $self;
}

1;

__END__
