# $Id: 12-feed.t,v 1.7 2004/05/08 13:20:58 btrott Exp $

use strict;

use Test;
use XML::Atom::Feed;
use URI;

BEGIN { plan tests => 20 };

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

$feed->add_link({ title => 'Number Three', rel => 'service.post',
                  href => 'http://www.example.com/atom',
                  type => 'application/x.atom+xml' });
my @links = $feed->link;
ok(scalar @links, 2);
ok(ref($links[-1]), 'XML::Atom::Link');
ok($links[-1]->title, 'Number Three');
ok($links[-1]->rel, 'service.post');
ok($links[-1]->href, 'http://www.example.com/atom');
ok($links[-1]->type, 'application/x.atom+xml');