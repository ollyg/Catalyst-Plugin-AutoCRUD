#!/usr/bin/perl

use strict;
use warnings FATAL => 'all';
use lib qw( t/lib );
use JSON::Any;

use Test::More 'no_plan';

# application loads
BEGIN {
    $ENV{AUTOCRUD_TESTING} = 1;
    $ENV{AUTOCRUD_CONFIG} = 't/lib/list_returns_bylist.conf';
    use_ok "Test::WWW::Mechanize::Catalyst::AJAX" => "TestAppCustomConfig";
}
my $mech = Test::WWW::Mechanize::Catalyst::AJAX->new;

$mech->get_ok("/autocrud/site/default/schema/dbic/source/album/dumpmeta", "Get metadata for album table");
my $content = JSON::Any->from_json($mech->content);

ok(exists $content->{site_conf}->{dbic}->{album}->{headings}, 'headings created from list_returns');

my $headings = $content->{site_conf}->{dbic}->{album}->{headings};
ok(ref $headings eq 'HASH', 'list_returns promoted to hash');

ok(scalar keys %$headings, 'only two columns selected');
ok(($headings->{title} eq 'Title' and $headings->{recorded} eq 'Recorded'), 'prettified headings');

__END__
