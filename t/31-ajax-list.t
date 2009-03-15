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
          'total' => 5,
          'rows' => [
                      {
                        'tracks' => [
                                      'Track 1.1',
                                      'Track 1.2',
                                      'Track 1.3'
                                    ],
                        'artist_id' => 'Mike Smith',
                        'id' => 1,
                        'title' => 'DJ Mix 1',
                        'recorded' => '1989-01-02',
                        'sleeve_notes' => 'SleeveNotes: id(1)',
                        'deleted' => 1
                      },
                      {
                        'tracks' => [
                                      'Track 2.1',
                                      'Track 2.2',
                                      'Track 2.3'
                                    ],
                        'artist_id' => 'Mike Smith',
                        'id' => 2,
                        'title' => 'DJ Mix 2',
                        'recorded' => '1989-02-02',
                        'sleeve_notes' => '',
                        'deleted' => 1
                      },
                      {
                        'tracks' => [
                                      'Track 3.1',
                                      'Track 3.2',
                                      'Track 3.3'
                                    ],
                        'artist_id' => 'Mike Smith',
                        'id' => 3,
                        'title' => 'DJ Mix 3',
                        'recorded' => '1989-03-02',
                        'sleeve_notes' => '',
                        'deleted' => 1
                      },
                      {
                        'tracks' => [
                                      'Pop Song One'
                                    ],
                        'artist_id' => 'David Brown',
                        'id' => 4,
                        'title' => 'Pop Songs',
                        'recorded' => '2007-05-30',
                        'sleeve_notes' => '',
                        'deleted' => 0
                      },
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

my $default_track_page = {
          'total' => 13,
          'rows' => [
                      {
                        'length' => '1:30',
                        'album_id' => 'DJ Mix 1',
                        'sales' => 5460000,
                        'id' => 1,
                        'title' => 'Track 1.1',
                        'copyright_id' => 'Label A',
                        'releasedate' => '1994-04-05'
                      },
                      {
                        'length' => '1:40',
                        'album_id' => 'DJ Mix 1',
                        'sales' => 1775000,
                        'id' => 2,
                        'title' => 'Track 1.2',
                        'copyright_id' => 'Label B',
                        'releasedate' => '1995-01-15'
                      },
                      {
                        'length' => '1:50',
                        'album_id' => 'DJ Mix 1',
                        'sales' => 2100000,
                        'id' => 3,
                        'title' => 'Track 1.3',
                        'copyright_id' => 'Label A',
                        'releasedate' => '1989-08-18'
                      },
                      {
                        'length' => '2:30',
                        'album_id' => 'DJ Mix 2',
                        'sales' => 153000,
                        'id' => 4,
                        'title' => 'Track 2.1',
                        'copyright_id' => 'Label B',
                        'releasedate' => '1990-01-04'
                      },
                      {
                        'length' => '2:40',
                        'album_id' => 'DJ Mix 2',
                        'sales' => 1020480,
                        'id' => 5,
                        'title' => 'Track 2.2',
                        'copyright_id' => 'Label A',
                        'releasedate' => '1991-11-11'
                      },
                      {
                        'length' => '2:50',
                        'album_id' => 'DJ Mix 2',
                        'sales' => 9625543,
                        'id' => 6,
                        'title' => 'Track 2.3',
                        'copyright_id' => 'Label B',
                        'releasedate' => '1980-07-21'
                      },
                      {
                        'length' => '3:30',
                        'album_id' => 'DJ Mix 3',
                        'sales' => 1953540,
                        'id' => 7,
                        'title' => 'Track 3.1',
                        'copyright_id' => 'Label A',
                        'releasedate' => '1998-06-12'
                      },
                      {
                        'length' => '3:40',
                        'album_id' => 'DJ Mix 3',
                        'sales' => 2668000,
                        'id' => 8,
                        'title' => 'Track 3.2',
                        'copyright_id' => 'Label B',
                        'releasedate' => '1998-01-04'
                      },
                      {
                        'length' => '3:50',
                        'album_id' => 'DJ Mix 3',
                        'sales' => 20000,
                        'id' => 9,
                        'title' => 'Track 3.3',
                        'copyright_id' => 'Label A',
                        'releasedate' => '1999-11-14'
                      },
                      {
                        'length' => '1:01',
                        'album_id' => 'Pop Songs',
                        'sales' => 2685000,
                        'id' => 10,
                        'title' => 'Pop Song One',
                        'copyright_id' => 'Label B',
                        'releasedate' => '1995-01-04'
                      }
                    ]
};

$mech->ajax_ok('/dbic/album/list', {}, $default_album_page, 'no args');

# page : the pager page number : defaults to 1

$mech->ajax_ok('/dbic/album/list', {page => 1}, $default_album_page, 'page one');

$mech->ajax_ok('/dbic/album/list', {page => 2}, {'total' => 5, 'rows' => []}, 'excess page');

$mech->ajax_ok('/dbic/album/list', {page => -1}, $default_album_page, 'negative page');

$mech->ajax_ok('/dbic/album/list', {page => 0}, $default_album_page, 'page zero');

$mech->ajax_ok('/dbic/album/list', {page => 'abc'}, $default_album_page, 'text page');

# limit : the number of records in a page : defaults to 10

my $two_records = Storable::dclone($default_album_page);
splice @{$two_records->{rows}}, 2 ;
$mech->ajax_ok('/dbic/album/list', {limit => 2}, $two_records, 'limit of two');

$mech->ajax_ok('/dbic/album/list', {limit => 20}, $default_album_page, 'excess limit');

$mech->ajax_ok('/dbic/album/list', {limit => -5}, $default_album_page, 'negative limit');

$mech->ajax_ok('/dbic/album/list', {limit => 0}, $default_album_page, 'zero limit');

$mech->ajax_ok('/dbic/album/list', {limit => 'abc'}, $default_album_page, 'text limit');

# page and limit together - both required : false is reset as default

my $page_and_limit = Storable::dclone($default_album_page);
$page_and_limit->{rows} = [ @{$page_and_limit->{rows}}[2,3] ];
$mech->ajax_ok('/dbic/album/list', {page => 2, limit => 2}, $page_and_limit, 'page and limit');

$mech->ajax_ok('/dbic/album/list', {page => -1, limit => 2}, $default_album_page, 'two recs neg page');

$mech->ajax_ok('/dbic/album/list', {page => 0, limit => 2}, $two_records, 'two recs zero page');

$mech->ajax_ok('/dbic/album/list', {page => 100, limit => 2}, {'total' => 5, 'rows' => []}, 'two recs excess page');

$mech->ajax_ok('/dbic/album/list', {page => 'abc', limit => 2}, $default_album_page, 'two recs text page');

$mech->ajax_ok('/dbic/album/list', {page => 1, limit => 20}, $default_album_page, 'one page excess limit');

$mech->ajax_ok('/dbic/album/list', {page => 2, limit => 20}, {'total' => 5, 'rows' => []}, 'page two excess limit');

$mech->ajax_ok('/dbic/album/list', {page => 2, limit => -5}, $default_album_page, 'page two neg limit');

$mech->ajax_ok('/dbic/album/list', {page => 1, limit => 0}, $default_album_page, 'one page zero limit');

$mech->ajax_ok('/dbic/album/list', {page => 2, limit => 0}, {'total' => 5, 'rows' => []}, 'page two zero limit');

$mech->ajax_ok('/dbic/album/list', {page => 2, limit => 'abc'}, $default_album_page, 'page two text limit');

# sort : single column to sort by : defaults to the PK (id, for album)

my $sort_recorded = Storable::dclone($default_album_page);
$sort_recorded->{rows} = [ @{$sort_recorded->{rows}}[0,1,2,4,3] ];
$mech->ajax_ok('/dbic/album/list', {sort => 'recorded'}, $sort_recorded, 'sort by recorded');

$mech->ajax_ok('/dbic/album/list', {sort => 'foobar'}, $default_album_page, 'sort by nonexistent');

$mech->ajax_ok('/dbic/album/list', {sort => 'tracks'}, $default_album_page, 'sort by multi rel');

$mech->ajax_ok('/dbic/album/list', {sort => ''}, $default_album_page, 'sort by unspecified');

my $sort_fk = Storable::dclone($default_album_page);
$sort_fk->{rows} = [ @{$sort_fk->{rows}}[4,3,0,1,2] ];
$mech->ajax_ok('/dbic/album/list', {sort => 'artist_id'}, $sort_fk, 'sort by sfy FK');

# dir : direction of sort, ASC or DESC : defaults to ASC

$mech->ajax_ok('/dbic/album/list', {dir => 'ASC'}, $default_album_page, 'sort ASC');

my $sort_desc = Storable::dclone($default_album_page);
$sort_desc->{rows} = [ reverse @{$sort_desc->{rows}} ];
$mech->ajax_ok('/dbic/album/list', {dir => 'DESC'}, $sort_desc, 'sort DESC');

$mech->ajax_ok('/dbic/album/list', {dir => ''}, $default_album_page, 'empty sort');

$mech->ajax_ok('/dbic/album/list', {dir => 'foobar'}, $default_album_page, 'nonsense sort');

# sort and dir together

my $sort_rec_desc = Storable::dclone($default_album_page);
$sort_rec_desc->{rows} = [ @{$sort_rec_desc->{rows}}[3,4,2,1,0] ];
$mech->ajax_ok('/dbic/album/list', {sort => 'recorded', dir => 'DESC'}, $sort_rec_desc, 'sort by recorded DESC');

my $track_album_desc = Storable::dclone($default_track_page);
$track_album_desc->{rows} = [ @{$track_album_desc->{rows}}[9,6,7,8,3,4,5,0,1,2] ];
$mech->ajax_ok('/dbic/track/list', {sort => 'album_id', dir => 'DESC'}, $track_album_desc, 'sort by FK DESC');

$mech->ajax_ok('/dbic/album/list', {sort => 'foobar', dir => 'DESC'}, $sort_desc, 'sort by nonexistent DESC');

$mech->ajax_ok('/dbic/album/list', {sort => 'tracks', dir => 'DESC'}, $sort_desc, 'sort by multi rel DESC');

$mech->ajax_ok('/dbic/album/list', {sort => '', dir => 'DESC'}, $sort_desc, 'sort by unspecified DESC');

$mech->ajax_ok('/dbic/album/list', {sort => 'foobar', dir => ''}, $default_album_page, 'sort by nonexistent, empty dir');

$mech->ajax_ok('/dbic/album/list', {sort => 'tracks', dir => ''}, $default_album_page, 'sort by FK multi, empty dir');

$mech->ajax_ok('/dbic/album/list', {sort => '', dir => ''}, $default_album_page, 'empty dir and empty sort');

$mech->ajax_ok('/dbic/album/list', {sort => 'foobar', dir => 'foobar'}, $default_album_page, 'sort by nonexistent, nonsense dir');

$mech->ajax_ok('/dbic/album/list', {sort => 'tracks', dir => 'foobar'}, $default_album_page, 'sort by FK multi, nonsense dir');

$mech->ajax_ok('/dbic/album/list', {sort => '', dir => 'foobar'}, $default_album_page, 'empty sort, nonsense dir');

# filter fields : build a WHERE LIKE clause

$mech->ajax_ok('/dbic/album/list', {'search.id' => ''}, $default_album_page, 'filter none');

$mech->ajax_ok('/dbic/album/list', {'search. ' => ''}, $default_album_page, 'filter col space');

$mech->ajax_ok('/dbic/album/list', {'search.' => ''}, $default_album_page, 'filter col missing');

$mech->ajax_ok('/dbic/album/list', {'search.foobar' => ''}, $default_album_page, 'filter col nonexistent');

$mech->ajax_ok('/dbic/album/list', {'search.id' => '%'}, $default_album_page, 'filter id by %');

$mech->ajax_ok('/dbic/album/list', {'search.id' => '!'}, {total => 0, rows => []}, 'filter to none');

my $case_correct = Storable::dclone($default_album_page);
$case_correct->{rows} = [ @{$case_correct->{rows}}[0,1,2] ];
$case_correct->{total} = 3;
$mech->ajax_ok('/dbic/album/list', {'search.title' => 'Mix'}, $case_correct, 'filter case correct');

$mech->ajax_ok('/dbic/album/list', {'search.title' => 'mix'}, $case_correct, 'filter case insensitive');

$mech->ajax_ok('/dbic/album/list', {'search.artist_id' => '%'}, $default_album_page, 'filter fk ignored');

__END__
