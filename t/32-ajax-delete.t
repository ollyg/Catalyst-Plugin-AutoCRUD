#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use Storable;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

my $default_sleeve_notes_page = {
          'total' => 1,
          'rows' => [
                      {
                        'id' => 1,
                        'text' => 'This is a groovy album.',
                        'album_id' => 'DJ Mix 2'
                      }
                    ]
};

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/delete', {}, {success => '0'}, 'no args');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/delete', {key => ''}, {success => '0'}, 'empty key');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/delete', {foobar => ''}, {success => '0'}, 'no key');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/delete', {key => 'foobar'}, {success => '0'}, 'no key match');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'This is a groovy album.'}, $default_sleeve_notes_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/delete', {key => '1'}, {success => '1'}, 'delete success');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'This is a groovy album.'}, {total => 0, rows => []}, 'check deleted');

$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/delete', {key => '1'}, {success => '0'}, 'delete again fails');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'This is a groovy album.'}, {total => 0, rows => []}, 'check deleted');

