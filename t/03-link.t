# $Id: 03-link.t,v 1.1 2003/12/30 06:58:18 btrott Exp $

use strict;

use Test;
use XML::Atom::Link;

BEGIN { plan tests => 7 };

my $link;

$link = XML::Atom::Link->new;
ok($link);
ok($link->elem);

$link->title('This is a test.');
ok($link->title, 'This is a test.');

$link->rel('alternate');
ok($link->rel, 'alternate');

$link->href('http://www.example.com/');
ok($link->href, 'http://www.example.com/');

$link->type('text/html');
ok($link->type, 'text/html');

ok($link->as_xml, <<XML);
<?xml version="1.0" encoding="utf-8"?>
<link xmlns="http://purl.org/atom/ns#" title="This is a test." rel="alternate" href="http://www.example.com/" type="text/html"/>
XML
