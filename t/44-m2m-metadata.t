#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestAppM2M" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the album table
$mech->get_ok( '/dbic/album/dumpmeta', 'Get album listframework metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'model'      => 'LFB::DBIC::Album',
    'table2path' => {
        'Album'        => 'album',
        'Artist Album' => 'artist_album',
        'Artist'       => 'artist'
    },
    'tab_order' => { 'LFB::DBIC::Album' => 1 },
    'main'      => {
        'mfks'    => { 'artist_albums' => 'Artists' },
        'pk'      => 'id',
        'moniker' => 'Album',
        'col_order' => [ 'id', 'title', 'recorded', 'deleted' ],
        'm2m'   => { 'artist_albums' => 'artist_id' },
        'title' => 'Album',
        'path'  => 'album',
        'cols'  => {
            'deleted' => {
                'required'    => 1,
                'extjs_xtype' => 'checkbox',
                'editable'    => 1,
                'heading'     => 'Deleted'
            },
            'recorded' => {
                'required'    => 1,
                'extjs_xtype' => 'datefield',
                'editable'    => 1,
                'heading'     => 'Recorded'
            },
            'title' => {
                'required' => 1,
                'editable' => 1,
                'heading'  => 'Title'
            },
            'id' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'editable'    => 0,
                'heading'     => 'Id'
            }
        }
    },
    'db2path'      => { 'Dbic' => 'dbic' },
    'dbpath2model' => { 'dbic' => 'LFB::DBIC' },
    'table_info'   => {
        'LFB::DBIC::Album' => {
            'mfks'    => { 'artist_albums' => 'Artists' },
            'pk'      => 'id',
            'moniker' => 'Album',
            'col_order' => [ 'id', 'title', 'recorded', 'deleted' ],
            'm2m'   => { 'artist_albums' => 'artist_id' },
            'title' => 'Album',
            'path'  => 'album',
            'cols'  => {
                'deleted' => {
                    'required'    => 1,
                    'extjs_xtype' => 'checkbox',
                    'editable'    => 1,
                    'heading'     => 'Deleted'
                },
                'recorded' => {
                    'required'    => 1,
                    'extjs_xtype' => 'datefield',
                    'editable'    => 1,
                    'heading'     => 'Recorded'
                },
                'title' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Title'
                },
                'id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'editable'    => 0,
                    'heading'     => 'Id'
                }
            }
        }
    },
    'path2model' => {
        'dbic' => {
            'artist'       => 'LFB::DBIC::Artist',
            'artist_album' => 'LFB::DBIC::ArtistAlbum',
            'album'        => 'LFB::DBIC::Album'
        }
    }
};

SKIP: {
        eval { require Lingua::EN::Inflect::Number };

        skip "Lingua::EN::Inflect::Number not installed", 1 if $@;

    is_deeply( $response, $expected, 'Metadata is as we expect' );
}

#warn $mech->content;
__END__
