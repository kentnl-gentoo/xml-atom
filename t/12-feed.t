# $Id: 12-feed.t,v 1.5 2004/01/05 16:14:20 btrott Exp $

use strict;

use Test;
use XML::Atom::Feed;
use URI;

BEGIN { plan tests => 14 };

my $feed;

$feed = XML::Atom::Feed->new('t/samples/feed.xml');
ok($feed->title, 'dive into atom');
ok(ref($feed->link), 'XML::Atom::Link');
ok($feed->link->href, 'http://diveintomark.org/atom/');
ok($feed->modified, '2003-08-25T11:39:42Z');
ok($feed->tagline, '');
ok($feed->id, 'tag:diveintomark.org,2003:14');
ok($feed->generator, 'http://www.movabletype.org/?v=2.64');
ok($feed->copyright, 'Copyright (c) 2003, Atom User');

my @entries = $feed->entries;
ok(scalar @entries, 15);
my $entry = $entries[0];
ok(ref($entry), 'XML::Atom::Entry');
ok($entry->title, 'Test');
ok($entry->content->body =~ /Python is cool stuff for ReSTy webapps./);

$entry = XML::Atom::Entry->new;
$entry->title('Foo');
$entry->content('<p>This is a test.</p>');
$feed->add_entry($entry);

@entries = $feed->entries;
ok(scalar @entries, 16);
my $last = $entries[-1];
ok($last->title, 'Foo');
#ok($last->content->body, '<p>This is a test.</p>');
