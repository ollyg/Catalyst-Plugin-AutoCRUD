package Catalyst::Plugin::AutoCRUD::View::JSON;
{
  $Catalyst::Plugin::AutoCRUD::View::JSON::VERSION = '2.131210';
}

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::View::JSON';

__PACKAGE__->config(
    expose_stash => 'json_data',
);

1;
