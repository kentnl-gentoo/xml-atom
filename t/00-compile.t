# $Id: 00-compile.t,v 1.2 2003/12/13 08:32:22 btrott Exp $

my $loaded;
BEGIN { print "1..1\n" }
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Feed;
use XML::Atom::API;
use XML::Atom::Person;
use XML::Atom::Content;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
