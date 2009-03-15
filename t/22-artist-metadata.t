#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';
use JSON;

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# get metadata for the artist table
$mech->get_ok( '/dbic/artist/dumpmeta', 'Get artist listframework metadata' );
is( $mech->ct, 'application/json', 'Metadata content type' );

my $response = JSON::from_json( $mech->content );

#use Data::Dumper;
#print STDERR Dumper $response;

my $expected = {
    'table_info' => {
        'LFB::DBIC::Artist' => {
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
        }
    },
    'model'      => 'LFB::DBIC::Artist',
    'table2path' => {
        'Album'        => 'album',
        'Copyright'    => 'copyright',
        'Sleeve Notes' => 'sleeve_notes',
        'Track'        => 'track',
        'Artist'       => 'artist'
    },
    'tab_order' => { 'LFB::DBIC::Artist' => 1 },
    'main'      => {
        'mfks'    => { 'albums' => 'Albums' },
        'pk'      => 'id',
        'moniker' => 'Artist',
        'col_order' => [ 'id', 'forename', 'surname', 'pseudonym', 'born' ],
        'path'      => 'artist',
        'title'     => 'Artist',
        'cols'      => {
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
