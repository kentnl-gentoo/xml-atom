# $Id: 02-entry.t,v 1.4 2003/09/29 04:19:26 btrott Exp $

use strict;

use Test;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Author;

BEGIN { plan tests => 25 }

my $entry = XML::Atom::Entry->new(Stream => 't/samples/entry-full.xml');
ok($entry->title, 'Guest Author');
ok($entry->link, 'http://www.thetrott.com/typepad/2003/07/guest_author.html');
ok($entry->id, 'tag:typepad.com:post:75207');
ok($entry->issued, '2003-07-21T02:47:34-07:00');
ok($entry->modified, '2003-08-22T18:36:57-07:00');
ok($entry->created, '2003-07-21T02:47:34-07:00');
ok($entry->summary, 'No, Ben isn\'t updating. It\'s me testing out guest author functionality....');
ok($entry->author);
ok(ref($entry->author) eq 'XML::Atom::Author');
ok($entry->author->name, 'Mena');
ok($entry->author->url, 'http://www.thetrott.com/typepad/');
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
ok($entry2->author->name, 'Mena');
ok($entry2->get($dc->subject), 'Food & Drink');
ok($entry2->content, '<div xmlns="http://www.w3.org/1999/xhtml"><p>No, Ben isn\'t updating. It\'s me testing out guest author functionality.</p></div>');

my $entry3 = XML::Atom::Entry->new;
my $author = XML::Atom::Author->new;
$author->name('Melody');
ok($author->name, 'Melody');
$author->email('melody@nelson.com');
$author->url('http://www.melodynelson.com/');
$entry3->title('Histoire');
ok(!$entry3->author);
$entry3->author($author);
ok($entry3->author);
ok($entry3->author->name, 'Melody');
