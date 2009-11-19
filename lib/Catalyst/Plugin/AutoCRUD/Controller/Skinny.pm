package Catalyst::Plugin::AutoCRUD::Controller::Skinny;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

# if user specifies frontend=skinny in the site config, Root will forward here

sub process : Private {
    my ($self, $c) = @_;
    $c->forward('rpc_browse');
}

# we also permit .../browse to force this frontend

# if user should call full RPC to .../browse
sub rpc_browse : Chained('/autocrud/root/call') PathPart('browse') Args(0) {
    my ($self, $c) = @_;
    $c->forward('base');
    $c->detach('browse');
}

# need to hack into the chain from Root and fork at .../table
sub table : Chained('/autocrud/root/db') PathPart('') CaptureArgs(1) {
    my ($self, $c) = @_;
    $c->forward('/autocrud/root/source');
}

# re-set the template and some params defaults for Skinny frontend
sub base : Chained('table') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;

    my $page = $c->req->params->{'page'};
    $page = 1 if !defined $page or $page !~ m/^\d+$/;
    $c->stash->{page} = $page;

    my $limit = $c->req->params->{'limit'};
    $limit = 20 if !defined $limit or ($limit ne 'all' and $limit !~ m/^\d+$/);
    $c->stash->{limit} = $limit;
  
    # XXX we call the stash var sortby so as to appease TT
    my $sortby = $c->req->params->{'sort'};
    $sortby = $c->stash->{lf}->{main}->{pk} if !defined $sortby or $sortby !~ m/^\w+$/;
    $c->stash->{sortby} = $sortby;

    my $dir = $c->req->params->{'dir'};
    $dir = 'ASC' if !defined $dir or $dir !~ m/^\w+$/g;
    $c->stash->{dir} = $dir;

    $c->stash->{frontend} = 'skinny';
}

# pull in data by forwarding to JSON .../list, then send page and render
sub browse : Chained('base') Args(0) {
    my ($self, $c) = @_;

    $c->forward('/autocrud/ajax/list');
    # need to shift off the filters row
    shift @{ $c->stash->{json_data}->{rows} };

    my $pager = Data::Page->new;
    $pager->total_entries($c->stash->{json_data}->{total});
    $pager->entries_per_page($c->stash->{limit} eq 'all'
        ? $c->stash->{json_data}->{total} : $c->stash->{limit});
    $pager->current_page($c->stash->{page});

    $c->stash->{pager} = $pager;
    $c->stash->{title} = $c->stash->{lf}->{main}->{title} .' Browser';
    $c->stash->{template} = 'list.tt';

    $c->forward('/autocrud/root/end');
}

1;

__END__
