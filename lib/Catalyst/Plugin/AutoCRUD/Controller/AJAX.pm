package Catalyst::Plugin::AutoCRUD::Controller::AJAX;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';

use List::Util qw(first);
use Scalar::Util qw(blessed);
use overload ();

sub _filter_datetime {
    my $val = shift;
    if (eval { $val->isa( 'DateTime' ) }) {
        my $iso = $val->iso8601;
        $iso =~ s/T/ /;
        return $iso;
    }
    else {
        $val =~ s/[+-]\d\d$//;
        return $val;
    }
}

my %filter_for = (
    timefield => {
        from_db => \&_filter_datetime,
        to_db   => sub { shift },
    },
    xdatetime => {
        from_db => \&_filter_datetime,
        to_db   => sub { shift },
    },
    checkbox => {
        from_db => sub {
            my $val = shift;
            return 1 if $val eq 'true' or $val eq '1';
            return 0;
        },
        to_db   => sub {
            my $val = shift;
            return 1 if $val eq 'on' or $val eq '1';
            return 0;
        },
    },
    numberfield => {
        from_db => sub { shift },
        to_db   => sub {
            my $val = shift;
            return undef if !defined $val or $val eq '';
            return $val;
        },
    },
);

# stringify a row of fields according to rules described in our POD
sub _sfy {
    my $row = shift;
    return '' if !defined $row or !blessed $row;
    return (
        eval { $row->display_name }
        || (overload::Method($row, '""') ? $row.''
            : ( $row->result_source->source_name
                .": ". join(', ', map { "$_(${\$row->get_column($_)})" } $row->primary_columns) ))
    );
}

# find whether this DMBS supports ILIKE or just LIKE
sub _likeop_for {
    my $model = shift;
    my $sqlt_type = $model->result_source->storage->sqlt_type;
    my %ops = (
        SQLite => '-like',
    );
    return $ops{$sqlt_type} || '-ilike';
}

# we're going to check that calls to this RPC operation are allowed
sub acl : Private {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $db = $c->stash->{db};
    my $table = $c->stash->{table};

    my $acl_for = {
        create   => 'create_allowed',
        update   => 'update_allowed',
        'delete' => 'delete_allowed',
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

sub base : Chained('/autocrud/root/ajax') PathPart('') CaptureArgs(0) {
    my ($self, $c) = @_;
    $c->forward('acl');
    $c->stash->{current_view} = 'AutoCRUD::JSON';
}

sub end : ActionClass('RenderView') {}

sub dumpmeta : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->stash->{json_data} = $c->stash->{lf};
    return $self;
}

# allows us to pseudo-acl the create call separately from update
sub create : Chained('base') Args(0) {
    my ($self, $c) = @_; 
    $c->forward('update');
}

sub list : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my $site = $c->stash->{site};
    my $db = $c->stash->{db};
    my $table = $c->stash->{table};

    my $lf = $c->stash->{lf};
    my $info = $lf->{main};
    my $response = $c->stash->{json_data} = {};

    my $page  = $c->req->params->{'page'}  || 1;
    my $limit = $c->req->params->{'limit'} || 10;
    my $sort  = $c->req->params->{'sort'}  || $info->{pk};
    (my $dir  = $c->req->params->{'dir'}   || 'ASC') =~ s/\s//g;

    # sanity check the sort param
    $sort = $info->{pk} if $sort !~ m/^[\w ]+$/ or !exists $info->{cols}->{$sort};

    # set up pager, if needed
    my $search_opts = (($page =~ m/^\d+$/ and $limit =~ m/^\d+$/)
        ? { 'page' => $page, 'rows' => $limit, } : {});

    # find filter fields in UI form
    my $filter = {};
    foreach my $p (keys %{$c->req->params}) {
        next unless $p =~ m/^search\.([\w ]+)/;
        my $col = $1;
        next unless exists $info->{cols}->{$col};
        next if $info->{cols}->{$col}->{is_fk} or $info->{cols}->{$col}->{is_rr};

        # for numberish types the case insensitive functions may not work
        if (exists $info->{cols}->{$col}->{extjs_xtype}
            and $info->{cols}->{$col}->{extjs_xtype} eq 'numberfield') {
            $filter->{$col} = $c->req->params->{"search.$col"};
            next;
        }

        # construct search clause if any of the filter fields were filled in UI
        $filter->{"me.$col"} = {
            # find whether this DMBS supports ILIKE or just LIKE
            _likeop_for($c->model($lf->{model}))
                => '%'. $c->req->params->{"search.$col"} .'%'
        };
    }

    # sort col which can be passed to the db
    if ($dir =~ m/^(?:ASC|DESC)$/ and ! $info->{cols}->{$sort}->{is_fk}
                                  and ! $info->{cols}->{$sort}->{is_rr}) {
        $search_opts->{order_by} = \"me.$sort $dir";
    }

    my $rs = $c->model($lf->{model})->search($filter, $search_opts);
    my @columns = (exists $search_opts->{columns} ? @{$search_opts->{columns}}
                                                  : keys %{ $info->{cols} });

    $c->model($lf->{model})->result_source->storage->debug(1)
        if $c->debug;

    # make data structure for JSON output
    while (my $row = $rs->next) {
        my $data = {};
        foreach my $col (@columns) {
            if ($info->{cols}->{$col}->{is_fk} or $info->{cols}->{$col}->{is_rr}) {
                # here assume table names are sane perl identifiers
                $data->{$col} = _sfy($row->$col);
            }
            else {
                if (!defined eval{$row->get_column($col)}) {
                    $data->{$col} = '';
                    next;
                }
                else {
                    $data->{$col} = $row->get_column($col);
                }
            }

            if (exists $info->{cols}->{$col}->{extjs_xtype}
                and exists $filter_for{ $info->{cols}->{$col}->{extjs_xtype} }) {
                $data->{$col} =
                    $filter_for{ $info->{cols}->{$col}->{extjs_xtype} }->{from_db}->(
                        $data->{$col});
            }
        }
        foreach my $m (keys %{ $info->{mfks} }) {
            if (exists $info->{m2m}->{$m}) {
                my $target = $info->{m2m}->{$m};
                $data->{$m} = [ map { _sfy($_) } map {$_->$target} $row->$m->all ];
            }
            else {
                $data->{$m} = [ map { _sfy($_) } $row->$m->all ];
            }
        }
        push @{$response->{rows}}, $data;
    }

    # sort col which cannot be passed to the DB
    if ($info->{cols}->{$sort}->{is_fk} or $info->{cols}->{$sort}->{is_rr}) {
        @{$response->{rows}} = sort {
            $dir eq 'ASC' ? ($a->{$sort} cmp $b->{$sort})
                          : ($b->{$sort} cmp $a->{$sort})
        } @{$response->{rows}};
    }

    $response->{rows} ||= [];
    $response->{total} =
        eval {$rs->pager->total_entries} || scalar @{$response->{rows}};

    # sneak in a 'top' row for applying the filters
    my %searchrow = ();
    foreach my $col (keys %{$info->{cols}}) {
        my $ci = $info->{cols}->{$col};

        if (exists $ci->{is_fk}
            or exists $ci->{is_rr}
            or (exists $ci->{extjs_xtype} and $ci->{extjs_xtype} eq 'checkbox')) {

            $searchrow{$col} = '';
        }
        else {
            if (exists $c->req->params->{ 'search.'. $col }) {
                $searchrow{$col} = $c->req->params->{ 'search.'. $col };
            }
            else {
                $searchrow{$col} = '(click to add filter)';
            }
        }
    }
    unshift @{$response->{rows}}, \%searchrow;

    $c->model($lf->{model})->result_source->storage->debug(0)
        if $c->debug;

    return $self;
}

# updates (currently) involve building a stack of table rows to update/insert
# and then popping items off that stack, remembering the PK vals as we go,
# for the benefit of later stack items (stack is built for this purpose).

sub update : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my $lf = $c->stash->{lf};
    my $response = $c->stash->{json_data} = {};

    my $stack = _build_table_data($c, [], $lf->{model});
    if ($c->debug) {
        use Data::Dumper;
        $c->log->debug(Dumper {table_stack => $stack});
    }

    # stack is processed in one transaction, so either all rows are
    # updated, or none, and an error thrown.

    $c->model($lf->{model})->result_source->storage->debug(1)
        if $c->debug;
    my $success = eval {
        $c->model($lf->{model})->result_source->schema->txn_do(
            \&_process_row_stack, $c, $stack
        );
    };
    if ($c->debug) {
        use Data::Dumper;
        $c->log->debug(Dumper {success => $success, exception => $@});
    }
    $response->{'success'} = (($success && !$@) ? 1 : 0);

    $c->model($lf->{model})->result_source->storage->debug(0)
        if $c->debug;

    return $self;
}

sub _build_table_data {
    my ($c, $stack, $model) = @_;
    my $lf = $c->stash->{lf};
    my $params = $c->req->params;

    my $info = $lf->{table_info}->{$model};
    my $prefix = ($model eq $lf->{model} ? '' : "$info->{path}.");
    my @related = ();
    my $data = {};

    foreach my $col (keys %{$info->{cols}}) {
        my $ci = $info->{cols}->{$col};

        # fix for HTML standard which excludes checkboxes
        $params->{ $prefix . $col } ||= 'false'
            if exists $ci->{extjs_xtype} and $ci->{extjs_xtype} eq 'checkbox';

        if (exists $ci->{fk_model}) {
            if (exists $lf->{table_info}->{ $ci->{fk_model} }) {
            # FKs where we could have full row data for the FT
                my $ft = $lf->{table_info}->{ $ci->{fk_model} }->{path};

                # has the user submitted a new row in the related table?
                if (exists $params->{ 'checkbox.' . $ft }) {
                    # FIXME should be Model, Table, Col to support multi FK to
                    # same table
                    push @related, $ci->{fk_model};
                    next;
                }
                elsif ($ci->{is_rr}) { # skip reverse relations here
                    next;
                }
            }

            # okay, no full row for related table, maybe just an ID update?
            if ($params->{ "combobox.$col" } and ($model eq $lf->{model})) {
                my $pk = $lf->{main}->{pk};
                if (exists $params->{ $pk } and $params->{ $pk } ne '') {
                    my $this_row = eval { $c->model($lf->{model})->find( $params->{ $pk } ) };

                    # skip where the FK val isn't really an update
                    next if (blessed $this_row)
                        and (_sfy($this_row->$col) eq $params->{ "combobox.$col" });
                }
            }

            # FK val is an update, so set the value
            $data->{$col} = $params->{ 'combobox.' . $col } || undef
                if exists $params->{ 'combobox.' . $col };
        }
        else {
        # not a foreign key, so just update the row data
            if (exists $params->{ $prefix . $col }
                and ($ci->{editable} or $params->{ $prefix . $col })) {
                    # skip auto-inc cols unless they contain data

                # filter data before sending to the database
                if (exists $ci->{extjs_xtype}
                    and exists $filter_for{ $ci->{extjs_xtype} }) {
                    $params->{ $prefix . $col } =
                        $filter_for{ $ci->{extjs_xtype} }->{to_db}->(
                            $params->{ $prefix . $col }
                        );
                }

                $data->{$col} = $params->{$prefix . $col};
            }
        }
    }

    # work out whether this row is lacking in the values of some foreign cols
    my $needs_keys = 0;
    foreach my $col (keys %{$info->{cols}}) {
        my $ci = $info->{cols}->{$col};
        next unless exists $ci->{fk_model}
                and $ci->{fk_model} eq $lf->{model};

        if (!exists $data->{$col}) {
            $needs_keys = 1;
            last;
        }
    }

    # add row data to stack - which end depends on whether it needs PKs adding
    if ($needs_keys) {
        unshift @$stack, $data, $model;
    }
    else {
        push @$stack, $data, $model;
    }

    _build_table_data($c, $stack, $_) for @related;
    return $stack;
}

# pop items off the stack, update/insert rows, and track new PK vals
# this should be run within a transaction

sub _process_row_stack {
    my ($c, $stack) = @_;
    my $lf = $c->stash->{lf};
    my %stashed_keys;

    while (my ($model, $data) = (pop @$stack, pop @$stack)) {
        last if !defined $model;

        # fetch and include PK vals from previously inserted rows
        my $info = $lf->{table_info}->{$model};
        foreach my $col (keys %{$info->{cols}}) {
            my $ci = $info->{cols}->{$col};
            next unless exists $ci->{is_fk}
                and exists $stashed_keys{$ci->{fk_model}};
            $data->{$col} = $stashed_keys{$ci->{fk_model}};
        }

        # update or create the row; could this use a magic DBIC method?
        my $pk = $lf->{table_info}->{$model}->{pk};
        my $row = (( defined $data->{ $pk } )
            ? eval { $c->model($model)->find( $data->{ $pk } ) }
            : undef );
        $row = (( blessed $row )
            ? $row->set_columns( $data )
            : $c->model($model)->new_result( $data ) );

        $row->update_or_insert;
        $stashed_keys{$model} = $row->id;
    }
    
    return 1;
}

sub delete : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my $lf = $c->stash->{lf};
    my $response = $c->stash->{json_data} = {};
    my $params = $c->req->params;

    my $row = eval { $c->model($lf->{model})->find($params->{key}) };

    if (blessed $row) {
        $row->delete;
        $response->{'success'} = 1;
    }
    else {
        $response->{'success'} = 0;
    }

    return $self;
}

sub list_stringified : Chained('base') Args(0) {
    my ($self, $c) = @_;
    my $lf = $c->stash->{lf};
    my $response = $c->stash->{json_data} = {};

    my $pg    = $c->req->params->{'page'}   || 1;
    my $limit = $c->req->params->{'limit'}  || 5;
    my $query = $c->req->params->{'query'}  || '';
    my $fk    = $c->req->params->{'fkname'} || '';

    # sanity check foreign key, and set up string part search
    $fk =~ s/\s//g; $fk =~ s/^[^.]*\.//;
    $query = ($query ? qr/\Q$query\E/i : qr/./);

    if (!$fk
        or !exists $lf->{main}->{cols}->{$fk}
        or not (exists $lf->{main}->{cols}->{$fk}->{is_fk}
            or exists $lf->{main}->{cols}->{$fk}->{is_rr})) {

        $c->stash->{json_data} = {total => 0, rows => []};
        return $self;
    }
    
    my $rs = $c->model($lf->{model})
                ->result_source->related_source($fk)->resultset;

    my @data =  map  { { dbid => $_->id, stringified => _sfy($_) } }
                grep { _sfy($_) =~ m/$query/ } $rs->all;
    @data = sort { $a->{stringified} cmp $b->{stringified} } @data;

    my $page = Data::Page->new;
    $page->total_entries(scalar @data);
    $page->entries_per_page($limit);
    $page->current_page($pg);

    $response->{rows} = [ $page->splice(\@data) ];
    $response->{total} = $page->total_entries;

    return $self;
}

1;

__END__
