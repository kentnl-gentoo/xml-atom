# $Id: /mirror/code/XML-Atom/trunk/t/20-content-xhtml.t 3518 2006-08-16T05:34:58.799705Z miyagawa  $

use strict;
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Feed;

use Test::More tests => 2;

my $entry = XML::Atom::Entry->new;
$entry->content('<strong>Bold</strong>');
unlike $entry->as_xml, qr/<default:/, 'Stupid default: namespace has been stripped';

my $feed = XML::Atom::Feed->new;
$entry = XML::Atom::Entry->new;
$entry->content('<strong>Bold</strong>');
$feed->add_entry($entry);
unlike $feed->as_xml, qr/<default:/, 'Stupid default: namespace has been stripped';
