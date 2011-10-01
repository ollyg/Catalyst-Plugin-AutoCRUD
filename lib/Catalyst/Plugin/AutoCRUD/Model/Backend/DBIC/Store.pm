package Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::Store;

use strict;
use warnings FATAL => 'all';

our @EXPORT;
BEGIN {
    use base 'Exporter';
    @EXPORT = qw/ create list update delete list_stringified /;
}

use Data::Page;
use List::Util qw(first);
use List::MoreUtils qw(zip uniq);
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
        $val =~ s/(\.\d+)?[+-]\d\d$//;
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

# create a unique identifier for this row from PKs
sub _create_ID {
    my $row = shift;
    return join "\000\000",
        map { "$_\000${\$row->get_column($_)}" } $row->primary_columns;
}

# find whether this DMBS supports ILIKE or just LIKE
sub _likeop_for {
    my $model = shift;
    my $sqlt_type = $model->result_source->storage->sqlt_type;
    my %ops = (
        SQLite => '-like',
        MySQL  => '-like',
    );
    return $ops{$sqlt_type} || '-ilike';
}

# allows us to pseudo-acl the create call separately from update
sub create {
    my ($self, $c) = @_;
    return $self->update($c);
}

sub list {
    my ($self, $c) = @_;
    my $site = $c->stash->{cpac}->{g}->{site};
    my $db = $c->stash->{cpac_db};
    my $table = $c->stash->{cpac_table};

    my $conf = $c->stash->{cpac}->{tc};
    my $meta = $c->stash->{cpac}->{tm};
    my $response = $c->stash->{json_data} = {};
    my @columns = @{$conf->{cols}};

    my ($page, $limit, $sort, $dir) =
        @{$c->stash}{qw/ cpac_page cpac_limit cpac_sortby cpac_dir /};
    my $filter = {}; my $search_opts = {};

    # sanity check the sort param
    unless (defined $sort and $sort =~ m/^[\w ]+$/ and exists $meta->f->{$sort}) {
        $sort = $c->stash->{cpac}->{g}->{default_sort};
    }

    # we want to prefetch all related data for _sfy
    foreach my $rel (@columns) {
        next unless ($meta->f->{$rel}->is_foreign_key or $meta->f->{$rel}->extra('is_reverse'));
        next if $meta->f->{$rel}->extra('rel_type') and $meta->f->{$rel}->extra('rel_type') =~ m/_many$/;
        next if $meta->f->{$rel}->extra('masked_by');
        push @{$search_opts->{prefetch}}, $rel;
    }

    # use of FK or RR partial text filter must disable the DB-side page/sort
    my %delay_page_sort = ();
    foreach my $p (keys %{$c->req->params}) {
        next unless (my $col) = ($p =~ m/^cpac_filter\.([\w ]+)/);
        next unless exists $meta->f->{$col}
            and ($meta->f->{$col}->is_foreign_key or $meta->f->{$col}->extra('is_reverse'));

        $delay_page_sort{$col} += 1
            if $c->req->params->{"cpac_filter.$col"} !~ m/\000/;
    }

    # find filter fields in UI form that can be passed to DB
    foreach my $p (keys %{$c->req->params}) {
        next unless (my $col) = ($p =~ m/^cpac_filter\.([\w ]+)/);
        next unless exists $meta->f->{$col};
        next if exists $delay_page_sort{$col};
        my $val = $c->req->params->{"cpac_filter.$col"};

        # exact match on RR value (checked above)
        if ($meta->f->{$col}->extra('is_reverse')) {
            if ($meta->f->{$col}->extra('rel_type') eq 'many_to_many') {
                push @{$search_opts->{join}},
                    {@{ $meta->f->{$col}->extra('via') }};
                $col = $meta->f->{$col}->extra('via')->[1];
            }
            else {
                push @{$search_opts->{join}}, $col;
            }

            foreach my $i (split m/\000\000/, $val) {
                my ($k, $v) = split m/\000/, $i;
                $filter->{"$col.$k"} = $v;
            }
            next;
        }

        # exact match on FK value (checked above)
        if ($meta->f->{$col}->is_foreign_key) {
            my %fmap = zip @{$meta->f->{$col}->extra('ref_fields')},
                           @{$meta->f->{$col}->extra('fields')};
            foreach my $i (split m/\000\000/, $val) {
                my ($k, $v) = split m/\000/, $i;
                $filter->{"me.$fmap{$k}"} = $v;
            }
            next;
        }

        # for numberish types the case insensitive functions may not work
        # plus, an exact match is probably what the user wants (i.e. 1 not 1*)
        if ($meta->f->{$col}->extra('extjs_xtype')
            and $meta->f->{$col}->extra('extjs_xtype') eq 'numberfield') {
            $filter->{"me.$col"} = $c->req->params->{"cpac_filter.$col"};
            next;
        }

        # ordinary search clause if any of the filter fields were filled in UI
        $filter->{"me.$col"} = {
            # find whether this DMBS supports ILIKE or just LIKE
            _likeop_for($c->model($meta->extra('model')))
                => '%'. $c->req->params->{"cpac_filter.$col"} .'%'
        };
    }

    # any sort on FK -must- disable DB-side paging, unless we already know the
    # supplied filter is a legitimate PK of the related table
    if (($meta->f->{$sort}->is_foreign_key or $meta->f->{$sort}->extra('is_reverse'))
            and not (exists $c->req->params->{"cpac_filter.$sort"} and not exists $delay_page_sort{$sort})) {
        $delay_page_sort{$sort} += 1;
    }

    # sort col which can be passed to the db
    if ($dir =~ m/^(?:ASC|DESC)$/ and !exists $delay_page_sort{$sort}
        and not ($meta->f->{$sort}->is_foreign_key or $meta->f->{$sort}->extra('is_reverse'))) {
        $search_opts->{order_by} = \"me.$sort $dir";
    }

    # set up pager, if needed (if user filtering by FK then delay paging)
    if ($page =~ m/^\d+$/ and $limit =~ m/^\d+$/ and not scalar keys %delay_page_sort) {
        $search_opts->{page} = $page;
        $search_opts->{rows} = $limit;
    }

    if ($ENV{AUTOCRUD_TRACE} and $c->debug) {
        use Data::Dumper;
        $c->log->debug( Dumper [$filter, $search_opts] );
    }

    my $rs = $c->model($meta->extra('model'))->search($filter, $search_opts);
    $response->{rows} ||= [];

    if ($ENV{AUTOCRUD_TRACE} and $c->debug) {
        $c->model($meta->extra('model'))->result_source->storage->debug(1);
    }

    # make data structure for JSON output
    DBIC_ROW:
    while (my $row = $rs->next) {
        my $data = {};
        foreach my $col (@columns) {
            if (($meta->f->{$col}->is_foreign_key
                or $meta->f->{$col}->extra('is_reverse'))
                and not $meta->f->{$col}->extra('masked_by')) {

                if ($meta->f->{$col}->extra('rel_type')
                    and $meta->f->{$col}->extra('rel_type') =~ m/many_to_many$/) {

                    my $link = $meta->f->{$col}->extra('via')->[0];
                    my $target = $meta->f->{$col}->extra('via')->[1];

                    $data->{$col} = $row->can($link) ?
                        [ uniq sort map { _sfy($_) } map {$_->$target} $row->$link->all ] : [];
                }
                elsif ($meta->f->{$col}->extra('rel_type')
                       and $meta->f->{$col}->extra('rel_type') =~ m/has_many$/) {

                    $data->{$col} = $row->can($col) ?
                        [ uniq sort map { _sfy($_) } $row->$col->all ] : [];

                    # check filter on FK, might want to skip further processing/storage
                    if (exists $c->req->params->{"cpac_filter.$col"}
                            and exists $delay_page_sort{$col}) {
                        my $p_val = $c->req->params->{"cpac_filter.$col"};
                        my $fk_match = ($p_val ? qr/\Q$p_val\E/i : qr/./);

                        next DBIC_ROW if 0 == scalar grep {$_ =~ m/$fk_match/}
                                                          @{$data->{$col}};
                    }
                }
                else {
                    # here assume table names are sane perl identifiers
                    $data->{$col} = _sfy($row->$col);

                    # check filter on FK, might want to skip further processing/storage
                    if (exists $c->req->params->{"cpac_filter.$col"}
                            and exists $delay_page_sort{$col}) {
                        my $p_val = $c->req->params->{"cpac_filter.$col"};
                        my $fk_match = ($p_val ? qr/\Q$p_val\E/i : qr/./);

                        next DBIC_ROW if $data->{$col} !~ m/$fk_match/;
                    }
                }
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

            if ($meta->f->{$col}->extra('extjs_xtype')
                and exists $filter_for{ $meta->f->{$col}->extra('extjs_xtype') }) {
                $data->{$col} =
                    $filter_for{ $meta->f->{$col}->extra('extjs_xtype') }->{from_db}->(
                        $data->{$col});
            }
        }

        #if ($ENV{AUTOCRUD_TRACE} and $c->debug) {
        #    $c->log->debug( Dumper ['item:', $data] );
        #}
        push @{$response->{rows}}, $data;
    }

    if ($ENV{AUTOCRUD_TRACE} and $c->debug) {
        $c->log->debug( Dumper ['rows:', $response->{rows}] );
        $c->model($meta->extra('model'))->result_source->storage->debug(0);
    }

    # sort col which cannot be passed to the DB
    if (exists $delay_page_sort{$sort}) {
        @{$response->{rows}} = sort {
            $dir eq 'ASC' ? ($a->{$sort} cmp $b->{$sort})
                          : ($b->{$sort} cmp $a->{$sort})
        } @{$response->{rows}};
    }

    $response->{total} =
        eval {$rs->pager->total_entries} || scalar @{$response->{rows}};

    # user filtered by FK so do the paging now (will be S-L-O-W)
    if ($page =~ m/^\d+$/ and $limit =~ m/^\d+$/ and scalar keys %delay_page_sort) {
        my $pg = Data::Page->new;
        $pg->total_entries(scalar @{$response->{rows}});
        $pg->entries_per_page($limit);
        $pg->current_page($page);
        $response->{rows} = [ $pg->splice($response->{rows}) ];
        $response->{total} = $pg->total_entries;
    }

    # sneak in a 'top' row for applying the filters
    my %searchrow = ();
    foreach my $col (@columns) {
        my $ci = $meta->f->{$col};

        if ($ci->extra('extjs_xtype') and $ci->extra('extjs_xtype') eq 'checkbox') {
            $searchrow{$col} = '';
        }
        else {
            if (exists $c->req->params->{ 'cpac_filter.'. $col }) {
                $searchrow{$col} = $c->req->params->{ 'cpac_filter.'. $col };
            }
            else {
                $searchrow{$col} = '(click to add filter)';
            }
        }
    }
    unshift @{$response->{rows}}, \%searchrow;

    return $self;
}

# updates (currently) involve building a stack of table rows to update/insert
# and then popping items off that stack, remembering the PK vals as we go,
# for the benefit of later stack items (stack is built for this purpose).

sub update {
    my ($self, $c) = @_;
    my $cpac = $c->stash->{cpac_meta};
    my $response = $c->stash->{json_data} = {};

    my $stack = _build_table_data($c, [], $cpac->{model});
    #if ($c->debug) {
    #    use Data::Dumper;
    #    $c->log->debug(Dumper {table_stack => $stack});
    #}

    # stack is processed in one transaction, so either all rows are
    # updated, or none, and an error thrown.

    #$c->model($cpac->{model})->result_source->storage->debug(1)
    #    if $c->debug;
    my $success = eval {
        $c->model($cpac->{model})->result_source->schema->txn_do(
            \&_process_row_stack, $c, $stack
        );
    };
    #if ($c->debug) {
    #    use Data::Dumper;
    #    $c->log->debug(Dumper {success => $success, exception => $@});
    #}
    $response->{'success'} = (($success && !$@) ? 1 : 0);

    #$c->model($cpac->{model})->result_source->storage->debug(0)
    #    if $c->debug;

    return $self;
}

sub _build_table_data {
    my ($c, $stack, $model) = @_;
    my $cpac = $c->stash->{cpac_meta};
    my $params = $c->req->params;

    my $info = $cpac->{table_info}->{$model};
    my $prefix = ($model eq $cpac->{model} ? '' : "$info->{path}.");
    my @related = ();
    my $data = {};

    foreach my $col (keys %{$info->{cols}}) {
        my $ci = $info->{cols}->{$col};

        # fix for HTML standard which excludes checkboxes
        $params->{ $prefix . $col } ||= 'false'
            if exists $ci->{extjs_xtype} and $ci->{extjs_xtype} eq 'checkbox';

        if (exists $ci->{fk_model}) {
            if (exists $cpac->{table_info}->{ $ci->{fk_model} }) {
            # FKs where we could have full row data for the FT
                my $ft = $cpac->{table_info}->{ $ci->{fk_model} }->{path};

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
            if ($params->{ "combobox.$col" } and ($model eq $cpac->{model})) {
                my $pk = $cpac->{main}->{pk};
                if (exists $params->{ $pk } and $params->{ $pk } ne '') {
                    my $this_row = eval { $c->model($cpac->{model})->find( $params->{ $pk } ) };

                    # skip where the FK val isn't really an update
                    next if (blessed $this_row)
                        and (_sfy($this_row->$col) eq $params->{ "combobox.$col" });
                }
            }

            # FK val is an update, so set the value
            $data->{$col} = $params->{ 'combobox.' . $col } || undef
                if exists $params->{ 'combobox.' . $col };

            # rename col to real name, now we have data for it
            # (custom relation accessor name)
            $data->{ $ci->{masked_col} } = delete $data->{$col}
                if defined $data->{$col} and exists $ci->{masked_col};
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
                and $ci->{fk_model} eq $cpac->{model};

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
    my $cpac = $c->stash->{cpac_meta};
    my %stashed_keys;

    while (my ($model, $data) = (pop @$stack, pop @$stack)) {
        last if !defined $model;

        # fetch and include PK vals from previously inserted rows
        my $info = $cpac->{table_info}->{$model};
        foreach my $col (keys %{$info->{cols}}) {
            my $ci = $info->{cols}->{$col};
            next unless $ci->{is_fk} and exists $stashed_keys{$ci->{fk_model}};
            $col = $ci->{masked_col} if exists $ci->{masked_col};
            $data->{$col} = $stashed_keys{$ci->{fk_model}};
        }

        # update or create the row; could this use a magic DBIC method?
        my $pk = $cpac->{table_info}->{$model}->{pk};
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

sub delete {
    my ($self, $c) = @_;
    my $cpac = $c->stash->{cpac_meta};
    my $response = $c->stash->{json_data} = {};
    my $params = $c->req->params;

    my $row = eval { $c->model($cpac->{model})->find($params->{key}) };

    if (blessed $row) {
        $row->delete;
        $response->{'success'} = 1;
    }
    else {
        $response->{'success'} = 0;
    }

    return $self;
}

sub list_stringified {
    my ($self, $c) = @_;
    my $meta = $c->stash->{cpac}->{tm};
    my $response = $c->stash->{json_data} = {};

    my $page  = $c->req->params->{'page'}   || 1;
    my $limit = $c->req->params->{'limit'}  || 5;
    my $query = $c->req->params->{'query'}  || '';
    my $fk    = $c->req->params->{'fkname'} || '';

    # sanity check foreign key, and set up string part search
    $fk =~ s/\s//g; $fk =~ s/^[^.]*\.//;
    my $query_re = ($query ? qr/\Q$query\E/i : qr/./);

    if (!$fk
        or !exists $meta->f->{$fk}
        or not ($meta->f->{$fk}->is_foreign_key
            or $meta->f->{$fk}->extra('is_reverse'))) {

        $c->stash->{json_data} = {total => 0, rows => []};
        return $self;
    }
    
    my $rs = $c->model($meta->extra('model'))
                ->result_source->related_source($fk)->resultset;
    my @data = ();

    # first try a simple and quick primary key search
    if (my $single_result = eval{ $rs->find($query) }) {
        @data = ({
            dbid => _create_ID($single_result),
            stringified => _sfy($single_result),
        });
    }
    else {
        # do the full text search
        my @results =  map  { { dbid => _create_ID($_), stringified => _sfy($_) } }
                       grep { _sfy($_) =~ m/$query_re/ } $rs->all;
        @data = sort { $a->{stringified} cmp $b->{stringified} } @results;
    }

    my $pg = Data::Page->new;
    $pg->total_entries(scalar @data);
    $pg->entries_per_page($limit);
    $pg->current_page($page);

    $response->{rows} = [ $pg->splice(\@data) ];
    $response->{total} = $pg->total_entries;

    if ($ENV{AUTOCRUD_TRACE} and $c->debug) {
        use Data::Dumper;
        $c->log->debug( Dumper $response->{rows} );
    }

    return $self;
}

1;

__END__
