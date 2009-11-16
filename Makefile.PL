use inc::Module::Install 0.67;
perl_version '5.008001';
  
name           'Catalyst-Plugin-AutoCRUD';
all_from       'lib/Catalyst/Plugin/AutoCRUD.pm';

requires       'Catalyst::Runtime' => '5.70';
requires       'Catalyst::Model::DBIC::Schema' => 0;
requires       'Catalyst::View::JSON' => 0;
requires       'Catalyst::View::TT' => 0;
requires       'Catalyst::Action::RenderView' => 0;
requires       'MRO::Compat' => 0;

test_requires  'JSON::Any' => 0;
test_requires  'Test::More' => 0;
test_requires  'Test::WWW::Mechanize' => '1.16';
test_requires  'Test::WWW::Mechanize::Catalyst' => '0.42';

# resources 'MailingList' => 'http://groups.google.com/group/catalyst-plugin-autocrud';

WriteAll;

