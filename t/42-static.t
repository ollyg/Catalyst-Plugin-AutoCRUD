#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );

use Test::More 'no_plan';

# application loads
BEGIN { use_ok "Test::WWW::Mechanize::Catalyst" => "TestApp" }
my $mech = Test::WWW::Mechanize::Catalyst->new;

ok($mech->get('/static/foo'), 'call with duff file');
is($mech->status, 404, 'no file caused 404');

$mech->get_ok('/static/bin_closed.png', 'Get bin_closed.png');
is($mech->ct, 'image/png', 'PNG MIME for bin_closed.png');

$mech->get_ok('/static/xdatetime.js', 'Get xdatetime.js');
is($mech->ct, 'application/x-javascript', 'JS MIME for xdatetime.js');

ok($mech->get('/static/xdatetime.png'), 'call with mangled filename');
is($mech->status, 404, 'mangled file caused 404');

#warn $mech->content;
__END__
