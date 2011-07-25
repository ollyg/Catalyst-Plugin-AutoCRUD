package Catalyst::Plugin::AutoCRUD::Controller::Root;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Controller';
use Catalyst::Utils;
use File::Basename;

__PACKAGE__->mk_classdata(_site_conf_cache => {});

# the templates are squirreled away in ../templates
(my $pkg_path = __PACKAGE__) =~ s{::}{/}g;
my (undef, $directory, undef) = fileparse(
    $INC{ $pkg_path .'.pm' }
);

sub base : Chained PathPart('autocrud') CaptureArgs(0) {
    my ($self, $c) = @_;

    $c->stash->{current_view} = 'AutoCRUD::TT';
    $c->stash->{cpac_version} = 'CPAC v'
        . $Catalyst::Plugin::AutoCRUD::VERSION;
    $c->stash->{cpac_site} = 'default';
    $c->stash->{template} = 'list.tt';
    $c->stash->{cpac} = {};

    # load enough metadata to display schema and sources
    if (!exists $self->_site_conf_cache->{dispatch}) {
        my $dispatch = {};
        foreach my $backend ($self->_enumerate_backends($c)) {
            my $new_dispatch = $c->forward($backend, 'dispatch_table');
            foreach (keys %$new_dispatch) {$new_dispatch->{$_}->{backend} = $backend}
            $dispatch = Catalyst::Utils::merge_hashes($dispatch, $new_dispatch);
        }
        $self->_site_conf_cache->{dispatch} = $dispatch;
        $c->log->debug("autocrud: generated global dispatch table") if $c->debug;
    }

    $c->stash->{cpac}->{dispatch} = $self->_site_conf_cache->{dispatch};
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
    $c->stash->{cpac_site} = $site;
}

sub no_schema : Chained('site') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->detach('err_message');
}

sub schema : Chained('site') PathPart CaptureArgs(1) {
    my ($self, $c, $db) = @_;
    $c->stash->{cpac_db} = $db;
}

sub no_source : Chained('schema') PathPart('') Args(0) {
    my ($self, $c) = @_;
    $c->detach('err_message');
}

# we know both the schema and the source here
sub source : Chained('schema') PathPart Args(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
    $c->stash->{cpac_title} = $c->stash->{cpac}->{dispatch}
        ->{$c->stash->{cpac_db}}
        ->{sources}->{$c->stash->{cpac_table}}->{display_name} .' List';

    # allow frontend override in non-default site (default will be full-fat)
    $c->stash->{cpac_frontend} ||= $c->stash->{cpac}->{conf}->{frontend};
    my $fend = 'Controller::AutoCRUD::'. ucfirst $c->stash->{cpac_frontend};
    if ($c->controller($fend)) {
        $c->log->debug(sprintf 'autocrud: forwarding to f/end %s', $fend)
            if $c->debug;
        $c->forward($fend);
    }
}

# for AJAX calls
sub call : Chained('schema') PathPart('source') CaptureArgs(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
    $c->stash->{cpac_backend} = $c->stash->{cpac}->{dispatch}->{$c->stash->{cpac_db}}->{backend};
}

# =====================================================================

# we know both the schema and the source here
sub do_meta : Private {
    my ($self, $c, $table) = @_;
    $c->stash->{cpac_table} = $table;
    my $db = $c->stash->{cpac_db};
    my $site = $c->stash->{cpac_site};

    $c->detach('err_message') if !exists $c->stash->{cpac}->{dispatch}->{$db}
        or !exists $c->stash->{cpac}->{dispatch}->{$db}->{sources}->{$table};

    $c->forward('build_site_config');

    # ACLs on the schema and source from site config
    if ($c->stash->{cpac}->{conf}->{$db}->{hidden} eq 'yes') {
        if ($site eq 'default') {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_db') )]);
        }
        else {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_schema'), [$site] )]);
        }
    }
    if ($c->stash->{cpac}->{conf}->{$db}->{$table}->{hidden} eq 'yes') {
        if ($site eq 'default') {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_table'), [$db] )]);
        }
        else {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_source'), [$site, $db] )]);
        }
    }

    # can now lazily load the remaining metadata for this schema into our cache
    # it's the whole schema, because related table data is also required.
    if (!exists $self->_site_conf_cache->{meta}->{$db}) {
        $self->_site_conf_cache->{meta}->{$db} =
            $c->forward($c->stash->{cpac}->{dispatch}->{$db}->{backend}, 'schema_metadata');
        $c->log->debug("autocrud: generated schema metadata for [$db]") if $c->debug;
    }
    else {
        $c->log->debug("autocrud: retrieving cached schema metadata for [$db]") if $c->debug;
    }

    $c->stash->{cpac}->{meta} = $self->_site_conf_cache->{meta}->{$db};
}

sub verboden : Private {
    my ($self, $c, $target, $code) = @_;
    $code ||= 303; # 3xx so RenderView skips template
    $c->response->redirect( $target, $code );
    # detaches -> end
}

# when user has not selected a source, we don't know which backend to use
sub _enumerate_backends {
    my ($self, $c) = @_;

    my @backends = @{ $c->config->{'Plugin::AutoCRUD'}->{backends} };
    $c->log->debug('autocrud: backends are '. join ',', @backends) if $c->debug;
    return @backends;
}

# we know only the schema or no schema, or there is a problem
sub err_message : Private {
    my ($self, $c) = @_;
    $c->forward('build_site_config');

    # if there's only one schema, then we choose it and skip straight to
    # the tables display.
    if (scalar keys %{$c->stash->{cpac}->{dispatch}} == 1) {
        $c->stash->{cpac_db} = [keys %{$c->stash->{cpac}->{dispatch}}]->[0];
    }

    $c->stash->{cpac_frontend} ||= $c->stash->{cpac}->{conf}->{frontend};
    $c->stash->{template} = 'tables.tt';
}

# build site config for filtering the frontend
sub build_site_config : Private {
    my ($self, $c) = @_;

    # if we have it cached
    if (keys %{ $self->_site_conf_cache->{sites}->{$c->stash->{cpac_site}} }) {
        $c->stash->{cpac}->{conf} = $self->_site_conf_cache->{sites}->{$c->stash->{cpac_site}};
        $c->log->debug(sprintf "autocrud: retrieving cached config for site [%s]",
            $c->stash->{cpac_site}) if $c->debug;
        return;
    }

    my %defaults = (
        frontend => 'full-fat',
        create_allowed => 'yes',
        update_allowed => 'yes',
        delete_allowed => 'yes',
        dumpmeta_allowed => 'no',
        hidden => 'no',
        html_charset => 'utf-8',
    );
    $defaults{dumpmeta_allowed} = 'yes' if $ENV{AUTOCRUD_TESTING};

    # start with the default config for all sites
    my $site = Catalyst::Utils::merge_hashes({}, \%defaults);

    # add config from our plugin, without site options
    $site = Catalyst::Utils::merge_hashes($site, $c->config->{'Plugin::AutoCRUD'});
    delete $site->{sites}; # don't want all sites' config

    # load whatever the user set in current site's config
    $site = Catalyst::Utils::merge_hashes($site,
        ($c->config->{'Plugin::AutoCRUD'}->{sites}->{$c->stash->{cpac_site}} || {}));

    # then bubble up the prefs until each source def has a complete set
    foreach my $sc (keys %{ $c->stash->{cpac}->{dispatch} }) {
        $site->{$sc} = Catalyst::Utils::merge_hashes ({
                map {($_ => $site->{$_})} keys %defaults
            }, $site->{$sc});

        foreach my $so (keys %{ $c->stash->{cpac}->{dispatch}->{$sc}->{sources} }) {
            $site->{$sc}->{$so} = Catalyst::Utils::merge_hashes ({
                    map {($_ => $site->{$sc}->{$_})} keys %defaults
                }, $site->{$sc}->{$so});

            # override *_allowed if the source is read only
            if (not exists $c->stash->{cpac}->{dispatch}->{$sc}->{sources}->{$so}->{editable}
                or not $c->stash->{cpac}->{dispatch}->{$sc}->{sources}->{$so}->{editable}) {
                $site->{$sc}->{$so}->{create_allowed} = 'no';
                $site->{$sc}->{$so}->{update_allowed} = 'no';
                $site->{$sc}->{$so}->{delete_allowed} = 'no';
            }

            # back-compat work for list_returns
            if (exists $site->{$sc}->{$so}->{list_returns} and
                    (!exists $site->{$sc}->{$so}->{headings} and !exists $site->{$sc}->{$so}->{columns})) {

                $c->log->warn("AutoCRUD: 'list_returns' is deprecated for site config. ".
                    "Please migrate to using 'columns' and 'headings' as shown in the Documentation.");

                $site->{$sc}->{$so}->{headings} = delete $site->{$sc}->{$so}->{list_returns};

                # promote arrayref into hashref
                if (ref $site->{$sc}->{$so}->{headings} eq 'ARRAY') {
                    $site->{$sc}->{$so}->{headings} =  { map {$_ => undef} @{$site->{$sc}->{$so}->{headings}} };
                }

                # prettify the column headings 
                $site->{$sc}->{$so}->{headings}->{$_} ||= (join ' ', map ucfirst, split /[\W_]+/, lc $_)
                    for keys %{ $site->{$sc}->{$so}->{headings} };

                # columns generated from old list_returns
                $site->{$sc}->{$so}->{columns} = [ keys %{ $site->{$sc}->{$so}->{headings} } ];
            }

            # copy columns list as hashref for ease of lookups
            if (exists $site->{$sc}->{$so}->{columns}
                    and ref $site->{$sc}->{$so}->{columns} eq 'ARRAY') {
                $site->{$sc}->{$so}->{col_keys} = { map {$_ => 1} @{$site->{$sc}->{$so}->{columns}} };
            }

            # need stubs for TT
            $site->{$sc}->{$so}->{columns}  ||= [];
            $site->{$sc}->{$so}->{col_keys} ||= {};
            $site->{$sc}->{$so}->{headings} ||= {};
        }
    }

    $self->_site_conf_cache->{sites}->{$c->stash->{cpac_site}} = $site;
    $c->stash->{cpac}->{conf} = $self->_site_conf_cache->{sites}->{$c->stash->{cpac_site}};

    $c->log->debug(sprintf "autocrud: loaded config for site [%s]",
            $c->stash->{cpac_site}) if $c->debug;
}

sub helloworld : Chained('base') Args(0) {
    my ($self, $c) = @_;
    $c->forward('build_site_config');
    $c->stash->{cpac_title} = 'Hello World';
    $c->stash->{template} = 'helloworld.tt';
}

sub end : ActionClass('RenderView') {
    my ($self, $c) = @_;
    my $frontend = $c->stash->{cpac_frontend} || 'full-fat';

    my $tt_path = $c->config->{'Plugin::AutoCRUD'}->{tt_path};
    $tt_path = (defined $tt_path ? (ref $tt_path eq '' ? [$tt_path] : $tt_path ) : [] );

    push @$tt_path, "$directory../templates/$frontend";
    $c->stash->{additional_template_paths} = $tt_path;
}

1;
__END__
