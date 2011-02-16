package Catalyst::Plugin::AutoCRUD::View::JSON;
BEGIN {
  $Catalyst::Plugin::AutoCRUD::View::JSON::VERSION = '1.110470';
}

use strict;
use warnings FATAL => 'all';

use base 'Catalyst::View::JSON';
use JSON::XS ();

sub encode_json {
    my($self, $c, $data) = @_;

    my $encoder = JSON::XS->new->latin1->allow_nonref;
    return $encoder->encode($data);
}

__PACKAGE__->config(
    expose_stash => 'json_data',
);

1;
