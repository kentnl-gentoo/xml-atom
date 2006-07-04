# $Id: /mirror/cpan/xml-atom/trunk/t/20-content-xhtml.t 2903 2006-07-06T01:15:36.512143Z btrott  $

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
