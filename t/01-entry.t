# $Id: 01-entry.t,v 1.1 2003/09/08 03:11:18 btrott Exp $

use strict;

use Test;
use XML::Atom::Entry;

BEGIN { plan tests => 10 }

my $entry = XML::Atom::Entry->new(Stream => 't/samples/entry-full.xml');
ok($entry->title, 'Guest Author');
ok($entry->link, 'http://www.thetrott.com/typepad/2003/07/guest_author.html');
ok($entry->id, 'tag:typepad.com:post:75207');
ok($entry->issued, '2003-07-21T02:47:34-07:00');
ok($entry->modified, '2003-08-22T18:36:57-07:00');
ok($entry->created, '2003-07-21T02:47:34-07:00');
ok($entry->summary, 'No, Ben isn\'t updating. It\'s me testing out guest author functionality....');
ok($entry->content, '<div xmlns="http://www.w3.org/1999/xhtml"><p>No, Ben isn\'t updating. It\'s me testing out guest author functionality.</p></div>');

## xxx author name, url
## xxx test setting/getting different content encodings
## xxx encodings
## xxx Doc param

$entry->title('Foo Bar');
ok($entry->title, 'Foo Bar');

ok($entry->as_xml);
