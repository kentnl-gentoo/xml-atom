# $Id: 11-entry.t,v 1.8 2003/12/15 00:39:17 btrott Exp $

use strict;

use Test;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Person;

BEGIN { plan tests => 39 }

my $entry = XML::Atom::Entry->new(Stream => 't/samples/entry-ns.xml');
ok($entry->title, 'Unit Test 1');
ok($entry->content->body, '<img src="foo.gif" align="left"/> This is what you get when you do unit testing.');

$entry = XML::Atom::Entry->new(Stream => 't/samples/entry-full.xml');
ok($entry->title, 'Guest Author');
ok($entry->link, 'http://www.thetrott.com/typepad/2003/07/guest_author.html');
ok($entry->id, 'tag:typepad.com:post:75207');
ok($entry->issued, '2003-07-21T02:47:34-07:00');
ok($entry->modified, '2003-08-22T18:36:57-07:00');
ok($entry->created, '2003-07-21T02:47:34-07:00');
ok($entry->summary, 'No, Ben isn\'t updating. It\'s me testing out guest author functionality....');
ok($entry->author);
ok(ref($entry->author) eq 'XML::Atom::Person');
ok($entry->author->name, 'Mena');
$entry->author->name('Ben');
ok($entry->author->url, 'http://www.thetrott.com/typepad/');
my $dc = XML::Atom::Namespace->new(dc => 'http://purl.org/dc/elements/1.1/');
ok($entry->get($dc->subject), 'Food');
ok($entry->content);
ok($entry->content->body, '<p>No, Ben isn\'t updating. It\'s me testing out guest author functionality.</p>');

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
ok($entry2->author->name, 'Ben');
ok($entry2->get($dc->subject), 'Food & Drink');
ok($entry2->content);
ok($entry2->content->body, '<p>No, Ben isn\'t updating. It\'s me testing out guest author functionality.</p>');

my $entry3 = XML::Atom::Entry->new;
my $author = XML::Atom::Person->new;
$author->name('Melody');
ok($author->name, 'Melody');
$author->email('melody@nelson.com');
$author->url('http://www.melodynelson.com/');
$entry3->title('Histoire');
ok(!$entry3->author);
$entry3->author($author);
ok($entry3->author);
ok($entry3->author->name, 'Melody');

$entry = XML::Atom::Entry->new;
$entry->content('<p>Not well-formed.');
ok($entry->content->mode, 'escaped');
ok($entry->content->body, '<p>Not well-formed.');

$entry = XML::Atom::Entry->new( Stream => \$entry->as_xml );
ok($entry->content->mode, 'escaped');
ok($entry->content->body, '<p>Not well-formed.');

$entry = XML::Atom::Entry->new;
$entry->content("This is a test that should use base64\0.");
$entry->content->type('image/gif');
ok($entry->content->mode, 'base64');
ok($entry->content->body, "This is a test that should use base64\0.");
ok($entry->content->type, 'image/gif');

$entry = XML::Atom::Entry->new( Stream => \$entry->as_xml );
ok($entry->content->mode, 'base64');
ok($entry->content->body, "This is a test that should use base64\0.");
ok($entry->content->type, 'image/gif');
