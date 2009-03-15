#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

# these are tests for plugging LFB into applications with
# their own TT and RenderView installations, other controller actions.

# get test page from TestApp TT View
$mech->get_ok('/testpage', 'Get Test page');
is($mech->ct, 'text/html', 'Test page content type');
$mech->content_contains('This is a test', 'Test Page content');

# can stil get hello world from LFB TT View
$mech->get_ok('/helloworld', 'Get Hello World page');
is($mech->ct, 'text/html', 'Hello World page content type');
$mech->content_contains('Hello, World!', 'Hello World (View TT) page content');

# can still use LFB JSON View
$mech->get_ok('/dbic/album/dumpmeta', 'AJAX (View JSON) also works');
is( $mech->ct, 'application/json', 'Metadata content type' );
# $mech->content_contains('"model":"LFB::DBIC::Album","table_info":', 'AJAX data content');

#warn $mech->content;
__END__
