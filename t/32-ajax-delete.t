#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use Storable;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

my $default_album_page = {
          'total' => 1,
          'rows' => [
                      {
                        'tracks' => [
                                      'Hit Tune',
                                      'Hit Tune II',
                                      'Hit Tune 3'
                                    ],
                        'artist_id' => 'Adam Smith',
                        'id' => 5,
                        'title' => 'Greatest Hits',
                        'recorded' => '2002-05-21',
                        'sleeve_notes' => '',
                        'deleted' => 0
                      }
                    ]
};

$mech->ajax_ok('/site/default/schema/dbic/source/album/delete', {}, {success => '0'}, 'no args');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/album/delete', {key => ''}, {success => '0'}, 'empty key');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/album/delete', {foobar => ''}, {success => '0'}, 'no key');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/album/delete', {key => 'foobar'}, {success => '0'}, 'no key match');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/site/default/schema/dbic/source/album/delete', {key => '5'}, {success => '1'}, 'delete success');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, {total => 0, rows => []}, 'check deleted');

$mech->ajax_ok('/site/default/schema/dbic/source/album/delete', {key => '5'}, {success => '0'}, 'delete again fails');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, {total => 0, rows => []}, 'check deleted');

