# $Id: 12-feed.t,v 1.3 2003/12/15 18:11:59 btrott Exp $

use strict;

use Test;
use XML::Atom::Feed;

BEGIN { plan tests => 11 };

my $feed = XML::Atom::Feed->new(Stream => 't/samples/feed.xml');
ok($feed->title, 'dive into atom');
ok($feed->link, 'http://diveintomark.org/atom/');
ok($feed->modified, '2003-08-25T11:39:42Z');
ok($feed->tagline, '');
ok($feed->id, 'tag:diveintomark.org,2003:14');
ok($feed->generator, 'http://www.movabletype.org/?v=2.64');
ok($feed->copyright, 'Copyright (c) 2003, Atom User');

my @entries = $feed->entries;
ok(scalar @entries, 15);
my $entry = $entries[0];
ok($entry->title, 'Test');
ok($entry->content->body =~ /Python is cool stuff for ReSTy webapps./);

$entry = XML::Atom::Entry->new;
$entry->title('Foo');
$feed->add_entry($entry);

ok(scalar $feed->entries, 16);
