# $Id: 03-client.t,v 1.1 2003/09/08 03:11:18 btrott Exp $

use strict;

use Test;
use XML::Atom::API;
use XML::Atom::Entry;

BEGIN { plan tests => 7 }

my $URL = 'http://diveintomark.org/cgi-bin/atom.cgi/service=edit';

my $entry = XML::Atom::Entry->new;
$entry->title('Unit Test 1');
$entry->summary('This is what you get');
$entry->content('When you do unit testing.');

my $api = XML::Atom::API->new;
$api->username('joe2');
$api->auth_digest('ff73b4f5e7c01872ac1fb71ec6668e181d232ecf');

ok($api->introspect($URL));
ok($api->{uri}{'create-entry'});
ok($api->{uri}{'search-entries'});

my $url = $api->createEntry($entry) or die $api->errstr;
ok($url);

my $entry2 = $api->getEntry($url);
ok($entry2);
ok($entry2->title, 'Unit Test 1');

my $ok = $api->deleteEntry($url);
ok($ok);
