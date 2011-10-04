package Catalyst::Plugin::AutoCRUD::Controller::Root;
BEGIN {
  $Catalyst::Plugin::AutoCRUD::Controller::Root::VERSION = '1.112770';
}

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
    $c->stash->{cpac_meta} = {};
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
    $c->stash->{cpac_title} = $c->stash->{cpac_meta}->{main}->{title} .' List';

    # allow frontend override in non-default site (default will be full-fat)
    $c->stash->{cpac_frontend} ||= $c->stash->{site_conf}->{frontend};
    $c->forward('Controller::AutoCRUD::'. ucfirst $c->stash->{cpac_frontend})
        if $c->controller('AutoCRUD::'. ucfirst $c->stash->{cpac_frontend});
}

# for AJAX calls
sub call : Chained('schema') PathPart('source') CaptureArgs(1) {
    my ($self, $c) = @_;
    $c->forward('do_meta');
}

# =====================================================================

# we know both the schema and the source here
sub do_meta : Private {
    my ($self, $c, $table) = @_;
    $c->stash->{cpac_table} = $table;

    my $db = $c->stash->{cpac_db};
    my $site = $c->stash->{cpac_site};

    $c->stash->{cpac_backend_store} =
        $c->stash->{site_conf}->{$db}->{backend_store} ||
        ('Model::AutoCRUD::Backend::'. ($c->stash->{site_conf}->{$db}->{backend} || 'DBIC'));
    $c->stash->{cpac_backend_meta} =
        $c->stash->{site_conf}->{$db}->{backend_meta} ||
        ('Model::AutoCRUD::Metadata::'. ($c->stash->{site_conf}->{$db}->{backend} || 'DBIC'));

    $c->forward('build_site_config');

    # ACLs on the schema and source from site config
    if ($c->stash->{site_conf}->{$db}->{hidden}
        and $c->stash->{site_conf}->{$db}->{hidden} eq 'yes') {

        if ($site eq 'default') {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_db') )]);
        }
        else {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_schema'), [$site] )]);
        }
    }
    if ($c->stash->{site_conf}->{$db}->{$table}->{hidden}
        and $c->stash->{site_conf}->{$db}->{$table}->{hidden} eq 'yes') {

        if ($site eq 'default') {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_table'), [$db] )]);
        }
        else {
            $c->detach('verboden', [$c->uri_for( $self->action_for('no_source'), [$site, $db] )]);
        }
    }

    $c->stash->{cpac_meta} = $c->forward($c->stash->{cpac_backend_meta});
    $c->detach('err_message') if !defined $c->stash->{cpac_meta}->{model};
}

sub verboden : Private {
    my ($self, $c, $target, $code) = @_;
    $code ||= 303; # 3xx so RenderView skips template
    $c->response->redirect( $target, $code );
    # detaches -> end
}

# when user has not selected a source, we don't know which backend to use
sub _enumerate_metadata_backends {
    my ($self, $c) = @_;
    my $config = $c->config->{'Plugin::AutoCRUD'}->{sites}->{$c->stash->{cpac_site}};
    my @backends = qw/Model::AutoCRUD::Metadata::DBIC/;

    foreach my $s (sort keys %$config) {
        next unless exists $config->{$s} and exists $config->{$s}->{backend_meta};
        push @backends, $config->{$s}->{backend_meta};
    }
    $c->log->debug(join ':', 'Backends are', ' ', @backends) if $c->debug;
    return @backends;
}

# we know only the schema or no schema, or there is a problem
sub err_message : Private {
    my ($self, $c) = @_;

    $c->forward('build_site_config') if !exists $c->stash->{site_conf};

    # forward to each metadata builder to provide db data
    if (!defined $c->stash->{cpac_meta}->{db2path}) {
        foreach my $backend ($self->_enumerate_metadata_backends($c)) {
            $c->stash->{cpac_meta} = Catalyst::Utils::merge_hashes(
                $c->stash->{cpac_meta}, $c->forward($backend));
        }
    }

    # a fugly hack for back-compat - if there is only one schema running,
    # then set that and re-dispatch to the metadata builder to set sources list
    if (scalar keys %{$c->stash->{cpac_meta}->{dbpath2model}} == 1) {
        my $db = [keys %{$c->stash->{cpac_meta}->{dbpath2model}}]->[0];
        $c->stash->{cpac_db} = $db;
        my $backend = (exists $c->stash->{site_conf}->{$db}->{backend_meta}
            ? $c->stash->{site_conf}->{$db}->{backend_meta}
            : 'Model::AutoCRUD::Metadata::DBIC'); # the default
        $c->stash->{cpac_meta} = Catalyst::Utils::merge_hashes(
            $c->stash->{cpac_meta}, $c->forward($backend));
    }

    $c->stash->{cpac_frontend} ||= $c->stash->{site_conf}->{frontend};
    $c->stash->{template} = 'tables.tt';
}

# build site config for filtering the frontend
sub build_site_config : Private {
    my ($self, $c) = @_;
    my $site = $self->_site_conf_cache->{$c->stash->{cpac_site}} ||= {};
    my $cpac = {};

    # if we have it cached
    if ($site->{__built}) {
        $c->stash->{site_conf} = $site;
        $c->log->debug(sprintf "autocrud: retreived cached config for site [%s]",
            $c->stash->{cpac_site}) if $c->debug;
        return;
    }

    # first, prime our structure of schema and source aliases
    foreach my $backend ($self->_enumerate_metadata_backends($c)) {
        # get stash of db path parts
        my $meta = $c->forward($backend, 'build_db_info');
        foreach my $db (keys %{$meta->{dbpath2model}}) {
            $site->{$db} ||= {};
            # get stash of table path parts
            $c->forward($backend, 'build_table_info_for_db', [$meta, $db]);
            foreach my $table (keys %{$meta->{path2model}->{$db}}) {
                $site->{$db}->{$table} ||= {};
            }
        }
        # store this for setting override on *_allowed later
        $cpac = Catalyst::Utils::merge_hashes( $cpac, $meta );
    }

    # load whatever the user set in their site config
    $site = Catalyst::Utils::merge_hashes(
        ($c->config->{'Plugin::AutoCRUD'}->{sites}->{$c->stash->{cpac_site}} || {}),
        $site);

    my %defaults = (
        frontend => 'full-fat', # needlessly copied to schema & sources
        create_allowed => 'yes',
        update_allowed => 'yes',
        delete_allowed => 'yes',
        dumpmeta_allowed => 'no',
        hidden => 'no',
    );
    $defaults{dumpmeta_allowed} = 'yes' if $ENV{AUTOCRUD_TESTING};

    # merge defaults into user prefs
    $site = Catalyst::Utils::merge_hashes (\%defaults, $site);

    # then bubble up the prefs until each source def has a complete set
    foreach my $sc (keys %{$site}) {
        next unless ref $site->{$sc} eq 'HASH';
        $site->{$sc} = Catalyst::Utils::merge_hashes ({
                map {($_ => $site->{$_})} keys %defaults
            }, $site->{$sc});

        foreach my $so (keys %{$site->{$sc}}) {
            next unless ref $site->{$sc}->{$so} eq 'HASH';
            $site->{$sc}->{$so} = Catalyst::Utils::merge_hashes ({
                    map {($_ => $site->{$sc}->{$_})} keys %defaults
                }, $site->{$sc}->{$so});

            # override *_allowed if the source is read only
            if (not $cpac->{editable}->{$sc}->{$so}) {
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

    $site->{__built} = 1;
    $c->stash->{site_conf} = $site;
    $self->_site_conf_cache->{$c->stash->{cpac_site}} = $site;

    $c->log->debug(sprintf "autocrud: cached the config for site [%s]",
            $c->stash->{cpac_site}) if $c->debug;
}

sub helloworld : Chained('base') Args(0) {
    my ($self, $c) = @_;
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
