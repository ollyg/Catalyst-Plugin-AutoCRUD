#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the album table
$mech->get_ok( '/site/default/schema/dbic/source/album/dumpmeta', 'Get album autocrud metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'table_info' => {
        'AutoCRUD::DBIC::SleeveNotes' => {
            'pk'        => 'id',
            'moniker'   => 'SleeveNotes',
            'col_order' => [ 'id', 'text', 'album_id' ],
            'path'      => 'sleeve_notes',
            'title'     => 'Sleeve Notes',
            'cols'      => {
                'album_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'AutoCRUD::DBIC::Album',
                    'editable'    => 0,
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
        'AutoCRUD::DBIC::Artist' => {
            'mfks'    => { 'albums' => 'Albums' },
            'pk'      => 'id',
            'moniker' => 'Artist',
            'col_order' => [ 'id', 'forename', 'surname', 'pseudonym', 'born' ],
            'path'  => 'artist',
            'title' => 'Artist',
            'cols'  => {
                'pseudonym' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Pseudonym'
                },
                'forename' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Forename'
                },
                'born' => {
                    'required'    => 1,
                    'extjs_xtype' => 'datefield',
                    'editable'    => 1,
                    'heading'     => 'Born'
                },
                'id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'editable'    => 0,
                    'heading'     => 'Id'
                },
                'surname' => {
                    'required' => 1,
                    'editable' => 1,
                    'heading'  => 'Surname'
                }
            }
        },
        'AutoCRUD::DBIC::Album' => {
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
                    'fk_model' => 'AutoCRUD::DBIC::SleeveNotes',
                    'is_rr'    => 1
                },
                'artist_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'AutoCRUD::DBIC::Artist',
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
    'model'      => 'AutoCRUD::DBIC::Album',
    'table2path' => {
        'Album'        => 'album',
        'Copyright'    => 'copyright',
        'Sleeve Notes' => 'sleeve_notes',
        'Track'        => 'track',
        'Artist'       => 'artist'
    },
    'tab_order' => {
        'AutoCRUD::DBIC::SleeveNotes' => 3,
        'AutoCRUD::DBIC::Artist'      => 2,
        'AutoCRUD::DBIC::Album'       => 1
    },
    'main' => {
        'mfks'    => { 'tracks' => 'Tracks' },
        'pk'      => 'id',
        'moniker' => 'Album',
        'col_order' =>
          [ 'id', 'title', 'recorded', 'deleted', 'artist_id', 'sleeve_notes' ],
        'path'  => 'album',
        'title' => 'Album',
        'cols'  => {
            'sleeve_notes' => {
                'editable' => 1,
                'heading'  => 'Sleeve Notes',
                'fk_model' => 'AutoCRUD::DBIC::SleeveNotes',
                'is_rr'    => 1
            },
            'artist_id' => {
                'required'    => 1,
                'extjs_xtype' => 'numberfield',
                'fk_model'    => 'AutoCRUD::DBIC::Artist',
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
    },
    'path2model' => {
        'dbic' => {
            'sleeve_notes' => 'AutoCRUD::DBIC::SleeveNotes',
            'artist'       => 'AutoCRUD::DBIC::Artist',
            'album'        => 'AutoCRUD::DBIC::Album',
            'track'        => 'AutoCRUD::DBIC::Track',
            'copyright'    => 'AutoCRUD::DBIC::Copyright'
        }
    },
    'db2path'      => { 'Dbic' => 'dbic' },
    'dbpath2model' => { 'dbic' => 'AutoCRUD::DBIC' }

};

is_deeply( $response, $expected, 'Metadata is as we expect' );

#warn $mech->content;
__END__
