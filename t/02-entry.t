# $Id: 01-entry.t,v 1.3 2003/09/08 07:27:12 btrott Exp $

use strict;

use Test;
use XML::Atom;
use XML::Atom::Entry;

BEGIN { plan tests => 16 }

my $entry = XML::Atom::Entry->new(Stream => 't/samples/entry-full.xml');
ok($entry->title, 'Guest Author');
ok($entry->link, 'http://www.thetrott.com/typepad/2003/07/guest_author.html');
ok($entry->id, 'tag:typepad.com:post:75207');
ok($entry->issued, '2003-07-21T02:47:34-07:00');
ok($entry->modified, '2003-08-22T18:36:57-07:00');
ok($entry->created, '2003-07-21T02:47:34-07:00');
ok($entry->summary, 'No, Ben isn\'t updating. It\'s me testing out guest author functionality....');
my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
ok($entry->get($dc->subject), 'Food');
ok($entry->content, '<div xmlns="http://www.w3.org/1999/xhtml"><p>No, Ben isn\'t updating. It\'s me testing out guest author functionality.</p></div>');

## xxx author name, url
## xxx test setting/getting different content encodings
## xxx encodings
## xxx Doc param

$entry->title('Foo Bar');
ok($entry->title, 'Foo Bar');
$entry->set($dc->subject, 'Food & Drink');
ok($entry->get($dc->subject), 'Food & Drink');

ok(my $xml = $entry->as_xml);

my $entry2 = XML::Atom::Entry->new(Stream => \$xml);
ok($entry2);
ok($entry2->title, 'Foo Bar');
ok($entry2->get($dc->subject), 'Food & Drink');
ok($entry2->content, '<div xmlns="http://www.w3.org/1999/xhtml"><p>No, Ben isn\'t updating. It\'s me testing out guest author functionality.</p></div>');
