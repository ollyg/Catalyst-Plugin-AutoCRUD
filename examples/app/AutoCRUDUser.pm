package AutoCRUDUser;
use Catalyst qw(ConfigLoader AutoCRUD);

# you probably want to change the path to this file
__PACKAGE__->config( 'Plugin::ConfigLoader' => { file => 'autocruduser.conf' } );

__PACKAGE__->setup;
1;
