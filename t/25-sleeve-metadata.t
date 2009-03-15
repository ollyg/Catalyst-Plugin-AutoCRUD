#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the copyright table
$mech->get_ok( '/dbic/sleeve_notes/dumpmeta',
    'Get sleeve_notes listframework metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'table_info' => {
        'LFB::DBIC::SleeveNotes' => {
            'pk'        => 'id',
            'moniker'   => 'SleeveNotes',
            'col_order' => [ 'id', 'text', 'album_id' ],
            'path'      => 'sleeve_notes',
            'title'     => 'Sleeve Notes',
            'cols'      => {
                'album_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'LFB::DBIC::Album',
                    'editable'    => 1,
                    'heading'     => 'Album',
                    'is_fk'       => 1
                },
                'text' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Text'
                },
                'id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'editable'    => 0,
                    'heading'     => 'Id'
                }
            }
        },
        'LFB::DBIC::Album' => {
            'mfks'      => { 'tracks' => 'Tracks' },
            'pk'        => 'id',
            'moniker'   => 'Album',
            'col_order' => [
                'id',        'title', 'recorded', 'deleted',
                'artist_id', 'sleeve_notes'
            ],
            'path'  => 'album',
            'title' => 'Album',
            'cols'  => {
                'sleeve_notes' => {
                    'editable' => 0,
                    'heading'  => 'Sleeve Notes',
                    'fk_model' => 'LFB::DBIC::SleeveNotes',
                    'is_rr'    => 1
                },
                'artist_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'LFB::DBIC::Artist',
                    'editable'    => 1,
                    'heading'     => 'Artist',
                    'is_fk'       => 1
                },
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
    'model'      => 'LFB::DBIC::SleeveNotes',
    'table2path' => {
        'Album'        => 'album',
        'Copyright'    => 'copyright',
        'Sleeve Notes' => 'sleeve_notes',
        'Track'        => 'track',
        'Artist'       => 'artist'
    },
    'tab_order' => {
        'LFB::DBIC::SleeveNotes' => 1,
        'LFB::DBIC::Album'       => 2
    },
    'main' => {
        'pk'        => 'id',
        'moniker'   => 'SleeveNotes',
        'col_order' => [ 'id', 'text', 'album_id' ],
        'path'      => 'sleeve_notes',
        'title'     => 'Sleeve Notes',
        'cols'      => {
            'album_id' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'fk_model'    => 'LFB::DBIC::Album',
                'editable'    => 1,
                'heading'     => 'Album',
                'is_fk'       => 1
            },
            'text' => {
                'required' => 1,
                'editable' => 1,
                'heading'  => 'Text'
            },
            'id' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'editable'    => 0,
                'heading'     => 'Id'
            }
        }
    },
    'path2model' => {
        'dbic' => {
            'sleeve_notes' => 'LFB::DBIC::SleeveNotes',
            'artist'       => 'LFB::DBIC::Artist',
            'album'        => 'LFB::DBIC::Album',
            'track'        => 'LFB::DBIC::Track',
            'copyright'    => 'LFB::DBIC::Copyright'
        }
    },
    'db2path'      => { 'Dbic' => 'dbic' },
    'dbpath2model' => { 'dbic' => 'LFB::DBIC' },
};

is_deeply( $response, $expected, 'Metadata is as we expect' );

#warn $mech->content;
__END__
