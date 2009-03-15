#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the track table
$mech->get_ok( '/dbic/track/dumpmeta', 'Get track listframework metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'table_info' => {
        'LFB::DBIC::Track' => {
            'pk'        => 'id',
            'moniker'   => 'Track',
            'col_order' => [
                'id',          'title',    'length', 'sales',
                'releasedate', 'album_id', 'copyright_id'
            ],
            'path'  => 'track',
            'title' => 'Track',
            'cols'  => {
                'length' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Length'
                },
                'album_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'LFB::DBIC::Album',
                    'editable'    => 1,
                    'heading'     => 'Album',
                    'is_fk'       => 1
                },
                'sales' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'editable'    => 1,
                    'heading'     => 'Sales'
                },
                'copyright_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'LFB::DBIC::Copyright',
                    'editable'    => 1,
                    'heading'     => 'Copyright',
                    'is_fk'       => 1
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
                },
                'releasedate' => {
                    'required'    => 1,
                    'extjs_xtype' => 'datefield',
                    'editable'    => 1,
                    'heading'     => 'Releasedate'
                }
            }
        },
        'LFB::DBIC::Copyright' => {
            'mfks'    => { 'tracks' => 'Tracks' },
            'pk'      => 'id',
            'moniker' => 'Copyright',
            'col_order' => [ 'id', 'rights_owner', 'copyright_year' ],
            'path'      => 'copyright',
            'title'     => 'Copyright',
            'cols'      => {
                'rights_owner' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Rights Owner'
                },
                'copyright_year' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'editable'    => 1,
                    'heading'     => 'Copyright Year'
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
                    'editable' => 1,
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
    'model'      => 'LFB::DBIC::Track',
    'table2path' => {
        'Album'        => 'album',
        'Copyright'    => 'copyright',
        'Sleeve Notes' => 'sleeve_notes',
        'Track'        => 'track',
        'Artist'       => 'artist'
    },
    'tab_order' => {
        'LFB::DBIC::Track'     => 1,
        'LFB::DBIC::Copyright' => 3,
        'LFB::DBIC::Album'     => 2
    },
    'main' => {
        'pk'        => 'id',
        'moniker'   => 'Track',
        'col_order' => [
            'id',          'title',    'length', 'sales',
            'releasedate', 'album_id', 'copyright_id'
        ],
        'path'  => 'track',
        'title' => 'Track',
        'cols'  => {
            'length' => {
                'required' => 1,
                'editable' => 1,
                'heading'  => 'Length'
            },
            'album_id' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'fk_model'    => 'LFB::DBIC::Album',
                'editable'    => 1,
                'heading'     => 'Album',
                'is_fk'       => 1
            },
            'sales' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'editable'    => 1,
                'heading'     => 'Sales'
            },
            'copyright_id' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'fk_model'    => 'LFB::DBIC::Copyright',
                'editable'    => 1,
                'heading'     => 'Copyright',
                'is_fk'       => 1
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
            },
            'releasedate' => {
                'required'    => 1,
                'extjs_xtype' => 'datefield',
                'editable'    => 1,
                'heading'     => 'Releasedate'
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
