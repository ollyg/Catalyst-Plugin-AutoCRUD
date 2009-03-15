use inc::Module::Install 0.67;
perl_version '5.008001';
  
name           'CatalystX-ListFramework-Builder';
all_from       'lib/CatalystX/ListFramework/Builder.pm';

requires       'Catalyst::Runtime' => '5.70';
requires       'Catalyst::Model::DBIC::Schema' => 0;
requires       'Catalyst::View::JSON' => 0;
requires       'Catalyst::View::TT' => 0;
requires       'Catalyst::Action::RenderView' => 0;
requires       'MRO::Compat' => 0;

test_requires  'Test::More' => 0;
test_requires  'Test::WWW::Mechanize' => '1.16';
test_requires  'Test::WWW::Mechanize::Catalyst' => '0.42';

WriteAll;

