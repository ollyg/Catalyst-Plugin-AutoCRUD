package Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC;

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model';

__PACKAGE__->mk_classdata(_schema_cache => {});

use Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::Store;
use Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::Metadata;

sub backend_name { return 'DBIC' }

1;
