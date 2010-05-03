#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON;

# application loads
BEGIN {
    $ENV{AUTOCRUD_TESTING} = 1;
    use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp"
}
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the copyright table
$mech->get_ok( '/site/default/schema/dbic/source/sleeve_notes/dumpmeta',
    'Get sleeve_notes autocrud metadata' );
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
                    'editable'    => 1,
                    'heading'     => 'Album',
                    'is_fk'       => 1,
                    'masked_col'  => 'album_id'
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
                    'editable'    => 0,
                    'heading'     => 'Sleeve Notes',
                    'fk_model'    => 'AutoCRUD::DBIC::SleeveNotes',
                    'is_rr'       => 1,
                    'foreign_col' => 'album_id'
                },
                'artist_id' => {
                    'required'    => 1,
                    'extjs_xtype' => 'numberfield',
                    'fk_model'    => 'AutoCRUD::DBIC::Artist',
                    'editable'    => 1,
                    'heading'     => 'Artist',
                    'is_fk'       => 1,
                    'masked_col'  => 'artist_id'
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
    'model'      => 'AutoCRUD::DBIC::SleeveNotes',
    'table2path' => {
        'dbic' => {
            'Album'        => 'album',
            'Copyright'    => 'copyright',
            'Sleeve Notes' => 'sleeve_notes',
            'Track'        => 'track',
            'Artist'       => 'artist'
        }
    },
    'tab_order' => {
        'AutoCRUD::DBIC::SleeveNotes' => 1,
        'AutoCRUD::DBIC::Album'       => 2
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
                'fk_model'    => 'AutoCRUD::DBIC::Album',
                'editable'    => 1,
                'heading'     => 'Album',
                'is_fk'       => 1,
                'masked_col'  => 'album_id'
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
    'editable' => {
        'dbic' => {
            'sleeve_notes' => 1,
            'artist'       => 1,
            'album'        => 1,
            'track'        => 1,
            'copyright'    => 1,
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
    'dbpath2model' => { 'dbic' => 'AutoCRUD::DBIC' },
};

is_deeply( $response->{cpac}, $expected, 'Metadata is as we expect' );

#warn $mech->content;
__END__
