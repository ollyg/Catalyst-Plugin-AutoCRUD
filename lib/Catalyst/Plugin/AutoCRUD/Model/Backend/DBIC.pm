package Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC;
{
  $Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::VERSION = '2.112890_002';
}

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::Model';

__PACKAGE__->mk_classdata(_schema_cache => {});

use Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::Store;
use Catalyst::Plugin::AutoCRUD::Model::Backend::DBIC::Metadata;

1;
