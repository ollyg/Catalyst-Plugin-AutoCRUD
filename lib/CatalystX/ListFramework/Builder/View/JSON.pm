package CatalystX::ListFramework::Builder::View::JSON;


use strict;
use warnings FATAL => 'all';

use base 'Catalyst::View::JSON';

__PACKAGE__->config(
    expose_stash => 'json_data',
);

1;
