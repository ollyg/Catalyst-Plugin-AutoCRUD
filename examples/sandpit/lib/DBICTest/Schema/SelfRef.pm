package # hide from PAUSE 
    DBICTest::Schema::SelfRef;

use base qw/DBICTest::BaseResult/;

__PACKAGE__->table('self_ref');
__PACKAGE__->add_columns(
  'id' => {
    data_type => 'integer',
    is_auto_increment => 1,
  },
  'name' => {
    data_type => 'varchar',
    size      => 100,
  },
  'self_ref_id' => {
    data_type => 'integer',
  },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->belongs_to( self_ref => 'DBICTest::Schema::SelfRef' => 'self_ref_id', { join_type => 'left' } );
__PACKAGE__->has_many( aliases => 'DBICTest::Schema::SelfRefAlias' => 'self_ref' );

1;
