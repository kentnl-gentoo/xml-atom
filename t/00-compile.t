# $Id: 00-compile.t,v 1.1 2003/09/08 03:11:18 btrott Exp $

my $loaded;
BEGIN { print "1..1\n" }
use XML::Atom;
use XML::Atom::Entry;
use XML::Atom::Feed;
use XML::Atom::API;
$loaded++;
print "ok 1\n";
END { print "not ok 1\n" unless $loaded }
