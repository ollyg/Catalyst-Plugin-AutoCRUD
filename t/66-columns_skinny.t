#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN {
    $ENV{AUTOCRUD_CONFIG} = 't/lib/columns_extjs.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/dbic/album/browse", "Get HTML for album table");
#my $content = $mech->content;
#use Data::Dumper;
#print STDERR Dumper $content;

my @links = $mech->find_all_links(class => 'cpac_link');
ok(scalar @links == 2, 'number of columns in table');

ok($mech->find_link(class => 'cpac_link', text => 'Title'), 'first heading is Title');
ok($mech->find_link(class => 'cpac_link', text => 'Recorded'), 'second heading is Recorded');

__END__

