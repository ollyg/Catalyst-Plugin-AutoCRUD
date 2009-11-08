package Catalyst::Plugin::AutoCRUD::Controller::Skinny;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

sub base : Chained('/autocrud/root/call') PathPart('') CaptureArgs(0) {
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

    $c->stash->{site_conf}->{frontend} = 'skinny';
}

sub browse : Chained('base') Args(0) {
    my ($self, $c) = @_;

    # prime the JSON cache
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
    $c->stash->{template} = 'browse.tt';

    $c->forward('/autocrud/root/end');
}

1;

__END__
