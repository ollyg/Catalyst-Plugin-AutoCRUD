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

my $testing_album_page = {
          'total' => 1,
          'rows' => [
                      {
                        'tracks' => [],
                        'artist_id' => 'Mike Smith',
                        'id' => 6,
                        'title' => 'Testing Hits',
                        'recorded' => '',
                        'sleeve_notes' => '',
                        'deleted' => 0
                      }
                    ]
};

my $new_album_page = {
          'total' => 1,
          'rows' => [
                      {
                        'tracks' => [],
                        'artist_id' => 'Charlie Thornton',
                        'id' => 7,
                        'title' => 'Testing Hits 2',
                        'recorded' => '',
                        'sleeve_notes' => '',
                        'deleted' => 0
                      }
                    ]
};

my $new_artist_page = {
          'total' => 1,
          'rows' => [
                      {
                        'albums' => ['Greatest Hits 2'],
                        'id' => 4,
                        'forename' =>'Bob', 
                        'surname' => 'Thornton',
                        'pseudonym' => '',
                        'born' => ''
                      }
                    ]
};

my $second_artist_page = {
          'total' => 1,
          'rows' => [
                      {
                        'albums' => ['Testing Hits 2'],
                        'id' => 5,
                        'forename' =>'Charlie', 
                        'surname' => 'Thornton',
                        'pseudonym' => '',
                        'born' => ''
                      }
                    ]
};

my $new_sleeve_page = {
          'total' => 1,
          'rows' => [
                      {
                        'id' => 2,
                        'text' =>'Very cool album indeed!', 
                        'album_id' => 'Greatest Hits 2',
                        'nonexistent_things' => [],
                      }
                    ]
};

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {}, {success => '0'}, 'add row, no data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'combobox.artist_id' => 3,
    title     => 'Greatest Hits',
    recorded  => '2002-05-21',
}, {success => '1'}, 'add row, dupe data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    'combobox.artist_id' => 1,
    recorded  => '2002-05-21',
}, {success => '0'}, 'add row, duff data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    'combobox.artist_id' => 1,
    title     => 'Testing Hits',
}, {success => '1'}, 'add minimal row');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Testing Hits'}, $testing_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'combobox.artist_id' => 3,
    foobar  => '2002-05-21',
}, {success => '1'}, 'edit row cols, extra data ignored');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'combobox.artist_id' => 3,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '1'}, 'edit row cols');

$default_album_page->{rows}->[0]->{title} = 'Greatest Hits 2';
$default_album_page->{rows}->[0]->{artist_id} = 'Adam Smith';
$default_album_page->{rows}->[0]->{recorded} = '2002-05-21';
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');

SKIP : {
    skip 'cannot test FK constraints with SQLite', 6;

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'combobox.artist_id' => 9,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '0'}, 'edit row fks, duff data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    'combobox.artist_id' => 1,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '1'}, 'edit row fks');

} # SKIP

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'checkbox.artist' => 'on',
    'combobox.artist_id' => 3,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '0'}, 'edit row add fwd related, duff data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'checkbox.artist' => 'on',
    'artist.forename' => 'Bob',
    'artist.surname' => 'Thornton',
    'combobox.artist_id' => 3,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
}, {success => '1'}, 'edit row add fwd related');

$default_album_page->{rows}->[0]->{artist_id} = 'Bob Thornton';
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/list', {'search.surname' => 'Thornton'}, $new_artist_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'combobox.artist_id' => 4,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
    'checkbox.sleeve_notes' => 'on',
}, {success => '0'}, 'edit row add rev related, duff data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    id => 5,
    'combobox.artist_id' => 4,
    title     => 'Greatest Hits 2',
    recorded  => '2002-05-21',
    'checkbox.sleeve_notes' => 'on',
    'sleeve_notes.text' => 'Very cool album indeed!',
}, {success => '1'}, 'edit row add rev related');
$default_album_page->{rows}->[0]->{sleeve_notes} = 'SleeveNotes: id(2)';
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Greatest Hits 2'}, $default_album_page, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/sleeve_notes/list', {'search.text' => 'Very cool album indeed'}, $new_sleeve_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    'artist.forename' => 'Charlie',
    'artist.surname' => 'Thornton',
    'checkbox.artist' => 'on',
    'combobox.artist_id' => 3,
}, {success => '0'}, 'add row, duff data, with related');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/list', {'search.forename' => 'Charlie'}, {total => 0, rows => []}, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    'checkbox.artist' => 'on',
    'artist.surname' => 'Thornton',
    'combobox.artist_id' => 1,
    title     => 'Testing Hits 2',
    recorded  => '2002-05-21',
}, {success => '0'}, 'add row, with related, duff data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Testing Hits 2'}, {total => 0, rows => []}, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/list', {'search.surname' => 'Thornton'}, $new_artist_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/album/update', {
    'checkbox.artist' => 'on',
    'artist.forename' => 'Charlie',
    'artist.surname' => 'Thornton',
    'combobox.artist_id' => 1,
    title     => 'Testing Hits 2',
}, {success => '1'}, 'add row, with related');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.title' => 'Testing Hits 2'}, $new_album_page, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/artist/list', {'search.forename' => 'Charlie'}, $second_artist_page, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/track/update', {
    title => 'Track Title',
    'combobox.album_id' => '',
    'checkbox.album' => 'on',
    'album.recorded' => '1999-05-21',
    'combobox.copyright_id' => '',
    'checkbox.copyright_id' => 'on',
    'rights owner' => 'Label D',
}, {success => '0'}, 'add row, with 2x related, one duff');
$mech->ajax_ok('/site/default/schema/dbic/source/track/list', {'search.title' => 'Track Title'}, {total => 0, rows => []}, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/copyright/list', {'search.rights owner' => 'Label D'}, {total => 0, rows => []}, 'check data');
$mech->ajax_ok('/site/default/schema/dbic/source/album/list', {'search.recorded' => '1999-05-21'}, {total => 0, rows => []}, 'check data');

$mech->ajax_ok('/site/default/schema/dbic/source/track/update', {
    'album.title' => 'Testing Hits 3',
    'checkbox.album' => 'on',
    'checkbox.copyright' => 'on',
    'combobox.artist_id' => 3,
    'copyright.rights owner' => 'Label D',
    title => 'Track Title',
}, {success => '1'}, 'add row, with 2x related');

$mech->ajax_ok('/site/default/schema/dbic/source/track/list', {'search.title' => 'Track Title'}, {
    'total' => 1,
    'rows' => [
                {
                  'length' => '',
                  'parent_album' => 'Testing Hits 3',
                  'sales' => '',
                  'id' => 14,
                  'title' => 'Track Title',
                  'copyright_id' => 'Label D',
                  'releasedate' => ''
                }
              ]
}, 'check data');


