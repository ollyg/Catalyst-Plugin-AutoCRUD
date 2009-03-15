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
$mech->get_ok( '/dbic/copyright/dumpmeta', 'Get copyright listframework metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'table_info' => {
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
        }
    },
    'model'      => 'LFB::DBIC::Copyright',
    'table2path' => {
        'Album'        => 'album',
        'Copyright'    => 'copyright',
        'Sleeve Notes' => 'sleeve_notes',
        'Track'        => 'track',
        'Artist'       => 'artist'
    },
    'tab_order' => { 'LFB::DBIC::Copyright' => 1 },
    'main'      => {
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
