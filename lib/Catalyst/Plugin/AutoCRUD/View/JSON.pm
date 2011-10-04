package Catalyst::Plugin::AutoCRUD::View::JSON;
BEGIN {
  $Catalyst::Plugin::AutoCRUD::View::JSON::VERSION = '1.112770';
}

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::View::JSON';

__PACKAGE__->config(
    expose_stash => 'json_data',
);

1;
