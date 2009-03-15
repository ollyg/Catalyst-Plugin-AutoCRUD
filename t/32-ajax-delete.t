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

$mech->ajax_ok('/dbic/album/delete', {}, {success => 'false'}, 'no args');
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');
exit;
$mech->ajax_ok('/dbic/album/delete', {key => ''}, {success => 'false'}, 'empty key');
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/dbic/album/delete', {foobar => ''}, {success => 'false'}, 'no key');
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/dbic/album/delete', {key => 'foobar'}, {success => 'false'}, 'no key match');
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check no delete');

$mech->ajax_ok('/dbic/album/delete', {key => '5'}, {success => 'true'}, 'delete success');
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Greatest Hits'}, {total => 0, rows => []}, 'check deleted');

$mech->ajax_ok('/dbic/album/delete', {key => '5'}, {success => 'false'}, 'delete again fails');
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Greatest Hits'}, {total => 0, rows => []}, 'check deleted');

