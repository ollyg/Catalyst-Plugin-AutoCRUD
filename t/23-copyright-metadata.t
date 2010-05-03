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
$mech->get_ok( '/site/default/schema/dbic/source/copyright/dumpmeta', 'Get copyright autocrud metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'table_info' => {
        'AutoCRUD::DBIC::Copyright' => {
            'mfks'    => { 'tracks' => 'Tracks' },
            'pk'      => 'id',
            'moniker' => 'Copyright',
            'col_order' => [ 'id', 'rights owner', 'copyright_year' ],
            'path'      => 'copyright',
            'title'     => 'Copyright',
            'cols'      => {
                'rights owner' => {
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
        }
    },
    'model'      => 'AutoCRUD::DBIC::Copyright',
    'table2path' => {
        'dbic' => {
            'Album'        => 'album',
            'Copyright'    => 'copyright',
            'Sleeve Notes' => 'sleeve_notes',
            'Track'        => 'track',
            'Artist'       => 'artist'
        }
    },
    'tab_order' => { 'AutoCRUD::DBIC::Copyright' => 1 },
    'main'      => {
        'mfks'    => { 'tracks' => 'Tracks' },
        'pk'      => 'id',
        'moniker' => 'Copyright',
        'col_order' => [ 'id', 'rights owner', 'copyright_year' ],
        'path'      => 'copyright',
        'title'     => 'Copyright',
        'cols'      => {
            'rights owner' => {
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
